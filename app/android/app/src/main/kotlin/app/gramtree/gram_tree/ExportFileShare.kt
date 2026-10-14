package app.gramtree.gram_tree

import android.app.Activity
import android.content.ClipData
import android.content.Intent
import androidx.core.content.FileProvider
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.IOException
import java.util.UUID

/** Invoked on the channel's background task queue; only presentation needs the UI thread. */
class ExportFileShare(private val activity: Activity) : MethodChannel.MethodCallHandler {
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "shareZip") {
            result.notImplemented()
            return
        }
        val args = call.arguments as? Map<*, *>
        val bytes = args?.get("bytes") as? ByteArray
        val filename = args?.get("filename") as? String
        if (bytes == null || bytes.isEmpty() || filename == null ||
            !filename.matches(Regex("[\\p{L}\\p{N}][\\p{L}\\p{N}._ -]{0,123}\\.[zZ][iI][pP]"))) {
            result.error("invalid_arguments", "Expected ZIP bytes and a safe ZIP basename.", null)
            return
        }

        var directory: File? = null
        try {
            val root = File(activity.cacheDir, "export_zip")
            if (!root.exists() && !root.mkdirs()) throw IOException("Cannot create export cache")
            cleanupExpiredExports(root)
            // Repeated exports with the same filename must not replace a URI already shared.
            directory = File(root, UUID.randomUUID().toString())
            if (!directory.mkdir()) throw IOException("Cannot create export directory")
            val file = File(directory, filename)
            file.outputStream().use { it.write(bytes) }
            val uri = FileProvider.getUriForFile(activity, "${activity.packageName}.export_files", file)
            val send = Intent(Intent.ACTION_SEND).apply {
                type = "application/zip"
                putExtra(Intent.EXTRA_STREAM, uri)
                clipData = ClipData.newRawUri("ZIP export", uri)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            val chooser = Intent.createChooser(send, "导出数据").apply {
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            val exportDirectory = directory
            activity.runOnUiThread {
                try {
                    if (activity.isFinishing || activity.isDestroyed) {
                        throw IllegalStateException("Activity is not available")
                    }
                    activity.startActivity(chooser)
                    // Android does not report when the receiver finishes reading. Retain the
                    // private cache file for 24 hours instead of deleting it on chooser dismissal.
                    result.success(null)
                } catch (_: Exception) {
                    File(exportDirectory, filename).delete()
                    exportDirectory.delete()
                    result.error("share_failed", "Could not open ZIP sharing.", null)
                }
            }
        } catch (_: Exception) {
            directory?.let {
                File(it, filename).delete()
                it.delete()
            }
            result.error("share_failed", "Could not prepare ZIP sharing.", null)
        }
    }

    private fun cleanupExpiredExports(root: File) {
        val cutoff = System.currentTimeMillis() - 24 * 60 * 60 * 1000L
        root.listFiles().orEmpty()
            .filter { it.isDirectory && it.name.matches(Regex("[a-f0-9-]{36}")) && it.lastModified() < cutoff }
            .sortedBy { it.lastModified() }
            .take(20)
            .forEach { directory ->
                // Only our single-level ZIP files; never recursively follow arbitrary paths.
                directory.listFiles().orEmpty().filter { it.isFile && it.extension.equals("zip", true) }
                    .forEach { it.delete() }
                directory.delete()
            }
    }
}
