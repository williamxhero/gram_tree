package app.gramtree.gram_tree

import io.flutter.embedding.android.FlutterActivity
import android.view.WindowManager
import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.net.Uri
import android.os.Build
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var receivedLink: String? = null
    private var shareChooserStarted = false

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        if (intent.action == Intent.ACTION_VIEW) receivedLink = intent.dataString
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "app.gramtree/share")
            .setMethodCallHandler { call, result ->
                if (call.method != "shareText" || call.arguments !is String) {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val intent = Intent(Intent.ACTION_SEND)
                    .setType("text/plain")
                    .putExtra(Intent.EXTRA_TEXT, call.arguments as String)
                try {
                    startActivity(Intent.createChooser(intent, null))
                    shareChooserStarted = true
                    result.success(null)
                } catch (error: Exception) {
                    result.error("share_unavailable", "System sharing is unavailable", null)
                }
            }
        // Local emulator evidence exercises Android's real intent resolver and
        // Flutter's onNewIntent delivery. Package scoping is not domain verification.
        // This harness is unavailable in non-debuggable production builds.
        if (applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE != 0) {
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "app.gramtree/integration_links")
                .setMethodCallHandler { call, result ->
                    when (call.method) {
                        "openShareLink" -> {
                            val uri = Uri.parse(call.arguments as? String ?: "")
                            if (uri.scheme != "https" || uri.host != "gramtree.app" ||
                                !uri.path.orEmpty().startsWith("/s/")) {
                                result.error("invalid_share_link", "Not a share link", null)
                                return@setMethodCallHandler
                            }
                            val viewIntent = Intent(Intent.ACTION_VIEW, uri)
                                .addCategory(Intent.CATEGORY_BROWSABLE)
                                .setPackage(packageName)
                                .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
                            val target = viewIntent.resolveActivity(packageManager)
                            if (target == null) {
                                result.error("link_not_resolved", "No matching manifest filter", null)
                            } else {
                                startActivity(viewIntent)
                                result.success(target.flattenToString())
                            }
                        }
                        "evidence" -> result.success(mapOf(
                            "receivedLink" to receivedLink,
                            "shareChooserStarted" to shareChooserStarted,
                        ))
                        else -> result.notImplemented()
                    }
                }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "app.gramtree/device_capabilities")
            .setMethodCallHandler { call, result ->
                if (call.method == "scheduleTimerReminder") {
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
