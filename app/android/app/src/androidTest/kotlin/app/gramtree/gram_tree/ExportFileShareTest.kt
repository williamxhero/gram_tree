package app.gramtree.gram_tree

import android.app.Activity
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.DocumentsContract
import android.provider.OpenableColumns
import android.test.InstrumentationTestCase
import android.view.accessibility.AccessibilityNodeInfo
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.concurrent.LinkedBlockingQueue
import java.util.concurrent.TimeUnit
import java.util.zip.ZipEntry
import java.util.zip.ZipInputStream
import java.util.zip.ZipOutputStream

/** Platform-only instrumentation: no test SDK, and no fake share/save intents. */
@Suppress("DEPRECATION")
class ExportFileShareTest : InstrumentationTestCase() {
    private lateinit var activity: Activity
    private lateinit var shareHandler: ExportFileShare
    private val saved = LinkedBlockingQueue<Intent>()
    private val documents = mutableListOf<Uri>()
    private val receiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) { saved.offer(intent) }
    }

    override fun setUp() {
        super.setUp()
        val context = instrumentation.targetContext
        if (Build.VERSION.SDK_INT >= 33) {
            context.registerReceiver(receiver, IntentFilter("app.gramtree.TEST_ZIP_SAVED"), Context.RECEIVER_EXPORTED)
        } else {
            context.registerReceiver(receiver, IntentFilter("app.gramtree.TEST_ZIP_SAVED"))
        }
        activity = instrumentation.startActivitySync(Intent(context, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        instrumentation.waitForIdleSync()
        shareHandler = ExportFileShare(activity)
    }

    override fun tearDown() {
        try {
            documents.forEach { check(DocumentsContract.deleteDocument(activity.contentResolver, it)) }
        } finally {
            instrumentation.targetContext.unregisterReceiver(receiver)
            instrumentation.runOnMainSync { activity.finish() }
            super.tearDown()
        }
    }

    fun testSaveZipAndRepeatedFilenameThroughSystemDocumentsUI() {
        val filename = "gramtree-instrumentation-${System.currentTimeMillis()}.zip"
        val first = shareAndSave(filename, "first export", filename)
        val second = shareAndSave(filename, "second export", "copy-$filename")
        val firstSource = requireNotNull(first.getParcelableExtra<Uri>("source"))
        val secondSource = requireNotNull(second.getParcelableExtra<Uri>("source"))
        assertFalse("Repeated exports must have distinct granted URIs", firstSource == secondSource)
        assertZip(firstSource, "first export")
        assertZip(secondSource, "second export")
        assertZip(requireNotNull(first.data), "first export")
        assertZip(requireNotNull(second.data), "second export")
    }

    fun testCancellationInvalidatesPreparationBeforePresentation() {
        val shareReplies = LinkedBlockingQueue<String>()
        shareHandler.onMethodCall(
            MethodCall("shareZip", mapOf("bytes" to ByteArray(32 * 1024 * 1024), "filename" to "cancel.zip")),
            replyQueue(shareReplies),
        )
        assertEquals("success", invoke(MethodCall("cancelShare", null)))
        assertEquals("share_cancelled", shareReplies.poll(30, TimeUnit.SECONDS))
        assertNull("Cancellation must not launch the system chooser", saved.poll(1, TimeUnit.SECONDS))
    }

    fun testInvalidArgumentsNeverOpenSharing() {
        for (filename in listOf("../escape.zip", "/absolute.zip", "bad\\name.zip", "not-zip.txt", "x.zip\n")) {
            val result = invoke(MethodCall("shareZip", mapOf("bytes" to zip("test"), "filename" to filename)))
            assertEquals("invalid_arguments", result)
        }
        assertEquals("invalid_arguments", invoke(MethodCall("shareZip", mapOf("bytes" to byteArrayOf(), "filename" to "x.zip"))))
        assertEquals("invalid_arguments", invoke(MethodCall("shareZip", mapOf("bytes" to "not bytes", "filename" to "x.zip"))))
        assertEquals("not_implemented", invoke(MethodCall("unknown", null)))
    }

    private fun shareAndSave(filename: String, text: String, destinationName: String): Intent {
        assertEquals("success", invoke(MethodCall("shareZip", mapOf("bytes" to zip(text), "filename" to filename))))
        click(waitForNode { it.text?.toString() == "Save test ZIP" })
        // Use the actual system document picker, not a test-owned file destination.
        click(waitForNode { it.contentDescription?.toString() == "Show roots" })
        click(waitForNode { it.text?.toString() == "Downloads" })
        val nameField = waitForNode { it.isEditable && it.text?.toString() == filename }
        if (filename != destinationName) {
            check(nameField.performAction(AccessibilityNodeInfo.ACTION_SET_TEXT, Bundle().apply {
                putCharSequence(AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE, destinationName)
            }))
        }
        click(waitForNode { it.isEnabled && it.text?.toString()?.equals("Save", true) == true })
        val result = saved.poll(30, TimeUnit.SECONDS) ?: error("Receiving app did not finish saving")
        val uri = requireNotNull(result.data) { "Receiver could not read/save the granted ZIP" }
        documents.add(uri)
        activity.contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)!!.use {
            check(it.moveToFirst())
            assertEquals(destinationName, it.getString(0))
        }
        assertZip(uri, text)
        return result
    }

    private fun invoke(call: MethodCall): String {
        val replies = LinkedBlockingQueue<String>()
        shareHandler.onMethodCall(call, replyQueue(replies))
        return replies.poll(30, TimeUnit.SECONDS) ?: error("Native share handler did not reply")
    }

    private fun replyQueue(replies: LinkedBlockingQueue<String>): MethodChannel.Result = object : MethodChannel.Result {
        override fun success(result: Any?) { replies.offer("success") }
        override fun error(code: String, message: String?, details: Any?) { replies.offer(code) }
        override fun notImplemented() { replies.offer("not_implemented") }
    }

    private fun zip(text: String): ByteArray {
        val bytes = ByteArrayOutputStream()
        ZipOutputStream(bytes).use {
            it.putNextEntry(ZipEntry("recipes.json"))
            it.write(text.toByteArray(Charsets.UTF_8))
            it.closeEntry()
        }
        return bytes.toByteArray()
    }

    private fun assertZip(uri: Uri, expected: String) {
        ZipInputStream(requireNotNull(activity.contentResolver.openInputStream(uri))).use {
            assertEquals("recipes.json", requireNotNull(it.nextEntry).name)
            assertEquals(expected, String(it.readBytes(), Charsets.UTF_8))
            assertNull("Unexpected ZIP entry", it.nextEntry)
        }
    }

    private fun waitForNode(predicate: (AccessibilityNodeInfo) -> Boolean): AccessibilityNodeInfo {
        val deadline = System.nanoTime() + TimeUnit.SECONDS.toNanos(30)
        while (System.nanoTime() < deadline) {
            findNode(instrumentation.uiAutomation.rootInActiveWindow, predicate)?.let { return it }
            Thread.sleep(100)
        }
        error("Required system share/save control was not visible within 30s")
    }

    private fun findNode(node: AccessibilityNodeInfo?, predicate: (AccessibilityNodeInfo) -> Boolean): AccessibilityNodeInfo? {
        if (node == null) return null
        if (predicate(node)) return node
        for (index in 0 until node.childCount) {
            findNode(node.getChild(index), predicate)?.let { return it }
        }
        return null
    }

    private fun click(node: AccessibilityNodeInfo) {
        var target: AccessibilityNodeInfo? = node
        while (target != null && !target.isClickable) target = target.parent
        check(requireNotNull(target).performAction(AccessibilityNodeInfo.ACTION_CLICK))
        instrumentation.waitForIdleSync()
    }
}
