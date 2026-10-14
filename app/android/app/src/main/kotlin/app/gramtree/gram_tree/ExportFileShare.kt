package app.gramtree.gram_tree

import android.app.Activity
import android.content.ClipData
import android.content.Intent
import android.os.Handler
import android.os.Looper
import androidx.core.content.FileProvider
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.IOException
import java.util.UUID
import java.util.concurrent.Executors

/** Cancellable native handoff for ZIP exports. */
class ExportFileShare(private val activity: Activity) : MethodChannel.MethodCallHandler {
    private val mainHandler = Handler(Looper.getMainLooper())
    private val writer = Executors.newSingleThreadExecutor { runnable ->
        Thread(runnable, "gramtree-export-writer").apply { isDaemon = true }
    }
    private val lock = Any()
    private var generation = 0L
    private var active = false
    private var activeDirectory: File? = null
    private var presentedDirectory: File? = null
    private var pendingResult: MethodChannel.Result? = null

    init {
        cleanupExpiredExports(File(activity.cacheDir, "export_zip"))
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "shareZip" -> shareZip(call.arguments, result)
            // Both names are accepted while the Dart seam rolls out. They cancel only
            // preparation; after ACTION_SEND is presented Android no longer owns the handoff.
            "cancelShare", "discardExport" -> cancelShare(result)
            else -> result.notImplemented()
        }
    }

    private fun shareZip(arguments: Any?, result: MethodChannel.Result) {
        val args = arguments as? Map<*, *>
        val bytes = args?.get("bytes") as? ByteArray
        val filename = args?.get("filename") as? String
        if (bytes == null || bytes.isEmpty() || filename == null ||
            !filename.matches(Regex("[\\p{L}\\p{N}][\\p{L}\\p{N}._ -]{0,123}\\.[zZ][iI][pP]"))) {
            result.error("invalid_arguments", "Expected ZIP bytes and a safe ZIP basename.", null)
            return
        }

        val directory: File
        val token: Long
        synchronized(lock) {
            if (active) {
                result.error("share_in_progress", "A ZIP export is already being prepared.", null)
                return
            }
            generation += 1
            token = generation
            active = true
            pendingResult = result
            directory = File(File(activity.cacheDir, "export_zip"), UUID.randomUUID().toString())
            activeDirectory = directory
        }

        writer.execute {
            val file = File(directory, filename)
            try {
                val root = directory.parentFile ?: throw IOException("Cannot create export cache")
                if (!root.exists() && !root.mkdirs()) throw IOException("Cannot create export cache")
                cleanupExpiredExports(root)
                if (!isCurrent(token)) {
                    deleteExport(directory)
                    return@execute
                }
                if (!directory.mkdir()) throw IOException("Cannot create export directory")
                // This write is deliberately off the channel/UI queue. cancelShare can run
                // concurrently, unlinking this private file and invalidating the token.
                file.outputStream().use { it.write(bytes) }
                if (!isCurrent(token)) {
                    deleteExport(directory)
                    return@execute
                }
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
                mainHandler.post { present(token, directory, chooser) }
            } catch (_: Exception) {
                deleteExport(directory)
                fail(token, "Could not prepare ZIP sharing.")
            }
        }
    }

    private fun present(token: Long, directory: File, chooser: Intent) {
        synchronized(lock) {
            if (!active || generation != token) {
                deleteExport(directory)
                return
            }
        }
        try {
            if (activity.isFinishing || activity.isDestroyed) throw IllegalStateException("Activity is not available")
            activity.startActivity(chooser)
            val pending: MethodChannel.Result?
            synchronized(lock) {
                active = false
                activeDirectory = null
                presentedDirectory = directory
                pending = pendingResult
                pendingResult = null
            }
            // Android does not report when the receiver finishes reading. Retain the
            // private cache file for 24 hours instead of deleting it on chooser dismissal.
            // A logout cancellation arriving before this point invalidates the token above.
            pending?.success(null)
        } catch (_: Exception) {
            deleteExport(directory)
            fail(token, "Could not open ZIP sharing.")
        }
    }

    private fun cancelShare(result: MethodChannel.Result) {
        val directory: File?
        val pending: MethodChannel.Result?
        synchronized(lock) {
            if (!active && presentedDirectory == null) {
                result.success(null)
                return
            }
            generation += 1
            active = false
            directory = activeDirectory ?: presentedDirectory
            activeDirectory = null
            presentedDirectory = null
            pending = pendingResult
            pendingResult = null
        }
        deleteExport(directory)
        pending?.error("share_cancelled", "ZIP sharing was cancelled.", null)
        result.success(null)
    }

    private fun isCurrent(token: Long): Boolean = synchronized(lock) {
        active && generation == token
    }

    private fun fail(token: Long, message: String) {
        mainHandler.post {
            val pending: MethodChannel.Result?
            synchronized(lock) {
                if (!active || generation != token) return@post
                active = false
                activeDirectory = null
                pending = pendingResult
                pendingResult = null
            }
            pending?.error("share_failed", message, null)
        }
    }

    private fun deleteExport(directory: File?) {
        if (directory == null) return
        directory.listFiles().orEmpty().forEach { it.delete() }
        directory.delete()
    }

    private fun cleanupExpiredExports(root: File) {
        val cutoff = System.currentTimeMillis() - 24 * 60 * 60 * 1000L
        root.listFiles().orEmpty()
            .filter { it.isDirectory && it.name.matches(Regex("[a-f0-9-]{36}")) && it.lastModified() < cutoff }
            .sortedBy { it.lastModified() }
            .take(20)
            .forEach { directory ->
                directory.listFiles().orEmpty().filter { it.isFile && it.extension.equals("zip", true) }
                    .forEach { it.delete() }
                directory.delete()
            }
    }

}
