package app.gramtree.gram_tree

import io.flutter.embedding.android.FlutterActivity
import android.view.WindowManager
import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Intent
import android.os.Build
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        MethodChannel(messenger, "app.gramtree/export_file")
            .setMethodCallHandler(ExportFileShare(this))
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "app.gramtree/device_capabilities")
            .setMethodCallHandler { call, result ->
                if (call.method == "scheduleTimerReminder" || call.method == "scheduleMonthlyReviewReminder") {
                    scheduleTimerReminder(call.arguments as Map<*, *>)
                    result.success(null)
                    return@setMethodCallHandler
                }
                if (call.method == "cancelTimerReminder") {
                    cancelTimerReminder(call.arguments as Map<*, *>)
                    result.success(null)
                    return@setMethodCallHandler
                }
                if (call.method != "setKeepScreenOn") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val enabled = call.arguments as? Boolean ?: false
                runOnUiThread {
                    if (enabled) window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                    else window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                }
                result.success(null)
            }
    }

    private fun timerIntent(args: Map<*, *>): PendingIntent {
        val id = args["id"] as String
        val intent = Intent(this, CookingTimerReceiver::class.java)
            .putExtra("id", id)
            .putExtra("title", args["title"] as? String)
            .putExtra("body", args["body"] as? String)
        return PendingIntent.getBroadcast(
            this, id.hashCode(), intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun scheduleTimerReminder(args: Map<*, *>) {
        val alarm = getSystemService(AlarmManager::class.java)
        val pending = timerIntent(args)
        val dueAtMillis = (args["dueAtMillis"] as Number).toLong()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && alarm.canScheduleExactAlarms()) {
            alarm.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, dueAtMillis, pending)
        } else {
            alarm.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, dueAtMillis, pending)
        }
    }

    private fun cancelTimerReminder(args: Map<*, *>) {
        getSystemService(AlarmManager::class.java).cancel(timerIntent(args))
    }
}
