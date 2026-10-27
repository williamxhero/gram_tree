package app.gramtree.gram_tree

import android.app.NotificationManager
import android.test.InstrumentationTestCase
import java.io.FileInputStream

/** Real OS alarm/notification assertions; never substitutes a Dart capability fake. */
@Suppress("DEPRECATION")
class MonthlyReviewReminderTest : InstrumentationTestCase() {
    private val id = "monthly_review:native-acceptance"
    private val context get() = instrumentation.targetContext
    private val manager get() = context.getSystemService(NotificationManager::class.java)

    private fun shell(command: String): String =
        instrumentation.uiAutomation.executeShellCommand(command).use { descriptor ->
            FileInputStream(descriptor.fileDescriptor).bufferedReader().readText()
        }

    override fun setUp() {
        super.setUp()
        // Permission rationale/denial is covered by the Flutter settings tests;
        // this isolated emulator test verifies the real alarm delivery boundary.
        shell("pm grant ${context.packageName} android.permission.POST_NOTIFICATIONS")
        shell("appops set ${context.packageName} SCHEDULE_EXACT_ALARM allow")
        MonthlyReviewReminder.cancel(context, id)
    }

    override fun tearDown() {
        MonthlyReviewReminder.cancel(context, id)
        super.tearDown()
    }

    private fun visible() = manager.activeNotifications.any { it.id == id.hashCode() }

    fun testScheduledDeliveryRenewsAndCancellationStopsFutureDelivery() {
        MonthlyReviewReminder.schedule(context, id, System.currentTimeMillis() + 2000, "America/New_York")
        val deadline = System.currentTimeMillis() + 15000
        while (!visible() && System.currentTimeMillis() < deadline) Thread.sleep(100)
        assertTrue("A scheduled monthly reminder must appear in the OS", visible())
        val notification = manager.activeNotifications.single { it.id == id.hashCode() }.notification
        assertEquals(CookingTimerReceiver.MONTHLY_CHANNEL, notification.channelId)
        assertTrue("The receiver must renew the next month without opening the app",
            shell("dumpsys alarm").contains("app.gramtree.MONTHLY_REVIEW.$id"))
        MonthlyReviewReminder.cancel(context, id)
        assertFalse("Disabling the category also clears delivered reminders", visible())
        MonthlyReviewReminder.schedule(context, id, System.currentTimeMillis() + 2000, "Asia/Shanghai")
        MonthlyReviewReminder.cancel(context, id)
        Thread.sleep(3500)
        assertFalse("A cancelled reminder must not be delivered", visible())
    }
}
