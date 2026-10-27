package app.gramtree.gram_tree

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.app.Notification

class CookingTimerReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getStringExtra("id") ?: return
        val monthly = intent.getStringExtra("timezone") != null
        if (monthly && !MonthlyReviewReminder.isEnabled(context, id)) return
        val manager = context.getSystemService(NotificationManager::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(
                NotificationChannel(
                    if (intent.getStringExtra("timezone") == null) CHANNEL else MONTHLY_CHANNEL,
                    if (intent.getStringExtra("timezone") == null) "做菜计时" else "每月回顾",
                    NotificationManager.IMPORTANCE_DEFAULT,
                )
            )
        }
        val openApp = PendingIntent.getActivity(
            context, id.hashCode(),
            Intent(context, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val notificationChannel = if (intent.getStringExtra("timezone") == null) CHANNEL else MONTHLY_CHANNEL
        val notification = Notification.Builder(context, notificationChannel)
            .setSmallIcon(android.R.drawable.ic_popup_reminder)
            .setContentTitle(intent.getStringExtra("title") ?: "做菜计时结束")
            .setContentText(intent.getStringExtra("body") ?: "可以回来继续做菜了。")
            .setContentIntent(openApp).setAutoCancel(true)
            .setPriority(Notification.PRIORITY_HIGH).build()
        try {
            manager.notify(id.hashCode(), notification)
        } finally {
            if (monthly) MonthlyReviewReminder.renew(context, id)
        }
    }

    companion object {
        const val CHANNEL = "cooking_timers"
        const val MONTHLY_CHANNEL = "monthly_review"
    }
}