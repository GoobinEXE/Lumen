package dev.prism.lumen

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/// Abre Ajustes do sistema (ficha do app, idioma do app, notificações).
class SystemSettingsBridge(
    private val activity: MainActivity,
) : MethodChannel.MethodCallHandler {
    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, CHANNEL).setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "open" -> {
                val target = call.argument<String>("target") ?: "app"
                result.success(open(target))
            }
            else -> result.notImplemented()
        }
    }

    private fun open(target: String): Boolean {
        val intent = when (target) {
            "locale" -> localeIntent()
            "notifications" -> notificationIntent()
            "healthConnect" -> healthConnectIntent()
            else -> appDetailsIntent()
        }
        return try {
            activity.startActivity(intent)
            true
        } catch (_: Exception) {
            try {
                activity.startActivity(appDetailsIntent())
                true
            } catch (_: Exception) {
                false
            }
        }
    }

    private fun appDetailsIntent(): Intent {
        return Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
            data = Uri.fromParts("package", activity.packageName, null)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
    }

    private fun localeIntent(): Intent {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            return Intent(Settings.ACTION_APP_LOCALE_SETTINGS).apply {
                data = Uri.fromParts("package", activity.packageName, null)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
        }
        return appDetailsIntent()
    }

    private fun notificationIntent(): Intent {
        return Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
            putExtra(Settings.EXTRA_APP_PACKAGE, activity.packageName)
            putExtra("app_package", activity.packageName)
            putExtra("app_uid", activity.applicationInfo.uid)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
    }

    /** Abre o Health Connect; se ausente, tenta a Play Store do pacote. */
    private fun healthConnectIntent(): Intent {
        val launch = activity.packageManager
            .getLaunchIntentForPackage(HEALTH_CONNECT_PACKAGE)
        if (launch != null) {
            return launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        return try {
            Intent(
                Intent.ACTION_VIEW,
                Uri.parse("market://details?id=$HEALTH_CONNECT_PACKAGE"),
            ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        } catch (_: Exception) {
            Intent(
                Intent.ACTION_VIEW,
                Uri.parse(
                    "https://play.google.com/store/apps/details?id=$HEALTH_CONNECT_PACKAGE",
                ),
            ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
    }

    companion object {
        const val CHANNEL = "dev.prism.lumen/system_settings"
        const val HEALTH_CONNECT_PACKAGE = "com.google.android.apps.healthdata"
    }
}
