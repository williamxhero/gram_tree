package app.gramtree.gram_tree

import android.app.AlarmManager
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import java.util.Calendar
import java.util.TimeZone

/** A calendar-month alarm, renewed by the receiver even without opening Flutter. */
object MonthlyReviewReminder {
    private const val STORE = "monthly_review_reminders"

    private fun pending(context: Context, id: String, timezone: String): PendingIntent =
        PendingIntent.getBroadcast(
            context, id.hashCode(),
            Intent(context, CookingTimerReceiver::class.java)
                .setAction("app.gramtree.MONTHLY_REVIEW.$id")
                .putExtra("id", id)
                .putExtra("timezone", timezone)
                .putExtra("title", "上月回顾已准备好")
                .putExtra("body", "来看看上个月的做菜记录和口味变化。"),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

    fun schedule(context: Context, id: String, dueAtMillis: Long, timezone: String) {
        context.getSharedPreferences(STORE, Context.MODE_PRIVATE).edit()
            .putString(id, timezone).commit()
        val alarm = context.getSystemService(AlarmManager::class.java)
        val intent = pending(context, id, timezone)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && alarm.canScheduleExactAlarms()) {
            alarm.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, dueAtMillis, intent)
        } else {
            alarm.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, dueAtMillis, intent)
        }
    }

    fun isEnabled(context: Context, id: String): Boolean =
        context.getSharedPreferences(STORE, Context.MODE_PRIVATE).contains(id)

    fun renew(context: Context, id: String) {
        val timezone = context.getSharedPreferences(STORE, Context.MODE_PRIVATE)
            .getString(id, null) ?: return
        val next = Calendar.getInstance(TimeZone.getTimeZone(timezone)).apply {
            set(Calendar.DAY_OF_MONTH, 1)
            add(Calendar.MONTH, 1)
            set(Calendar.HOUR_OF_DAY, 9)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        schedule(context, id, next.timeInMillis, timezone)
    }

    fun cancel(context: Context, id: String) {
        val store = context.getSharedPreferences(STORE, Context.MODE_PRIVATE)
        val timezone = store.getString(id, "UTC") ?: "UTC"
        store.edit().remove(id).commit()
        val intent = pending(context, id, timezone)
        context.getSystemService(AlarmManager::class.java).cancel(intent)
        intent.cancel()
        context.getSystemService(NotificationManager::class.java).cancel(id.hashCode())
    }
}
