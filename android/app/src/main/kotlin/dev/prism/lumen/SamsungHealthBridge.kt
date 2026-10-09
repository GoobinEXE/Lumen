package dev.prism.lumen

import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Ponte Samsung Health.
 *
 * Detecta o app Samsung Health. Quando o AAR do Samsung Health Data SDK
 * estiver em `android/app/libs/` e a classe HealthDataService existir,
 * [isSdkLinked] fica true e connect/read/write passam a usar o SDK.
 * Sem o AAR, o Flutter cai no Health Connect (fallback do facade).
 */
class SamsungHealthBridge(
    private val activity: MainActivity,
) : MethodChannel.MethodCallHandler {

    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, CHANNEL).setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isAvailable" -> result.success(isSamsungHealthInstalled())
            "isSdkLinked" -> result.success(isSdkLinked())
            "connect" -> result.success(connect())
            "requestPermissions" -> result.success(false)
            "hasPermissions" -> result.success(false)
            "resolveError" -> result.success(openSamsungHealthOrStore())
            "readSleep" -> result.success(emptyList<Map<String, Any?>>())
            "readRecovery" -> result.success(emptyList<Map<String, Any?>>())
            "readDemographics" -> result.success(null)
            "writeWater" -> result.success(false)
            "writeMindfulnessExercise" -> result.success(false)
            else -> result.notImplemented()
        }
    }

    private fun isSamsungHealthInstalled(): Boolean {
        return try {
            activity.packageManager.getPackageInfo(SAMSUNG_HEALTH_PACKAGE, 0)
            true
        } catch (_: PackageManager.NameNotFoundException) {
            false
        }
    }

    private fun isSdkLinked(): Boolean {
        return try {
            Class.forName("com.samsung.android.sdk.health.data.HealthDataService")
            true
        } catch (_: ClassNotFoundException) {
            false
        }
    }

    private fun connect(): Boolean {
        if (!isSdkLinked()) return false
        // Com o AAR linkado, a integração completa do HealthDataStore
        // entra aqui (partner Samsung + permissões por DataType).
        return false
    }

    private fun openSamsungHealthOrStore(): Boolean {
        return try {
            if (isSamsungHealthInstalled()) {
                val launch = activity.packageManager
                    .getLaunchIntentForPackage(SAMSUNG_HEALTH_PACKAGE)
                if (launch != null) {
                    activity.startActivity(launch)
                    return true
                }
            }
            val market = Intent(
                Intent.ACTION_VIEW,
                Uri.parse("market://details?id=$SAMSUNG_HEALTH_PACKAGE"),
            ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            activity.startActivity(market)
            true
        } catch (_: Exception) {
            try {
                val web = Intent(
                    Intent.ACTION_VIEW,
                    Uri.parse(
                        "https://play.google.com/store/apps/details?id=$SAMSUNG_HEALTH_PACKAGE",
                    ),
                ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                activity.startActivity(web)
                true
            } catch (_: Exception) {
                false
            }
        }
    }

    companion object {
        const val CHANNEL = "dev.prism.lumen/samsung_health_bridge"
        const val SAMSUNG_HEALTH_PACKAGE = "com.sec.android.app.shealth"
    }
}
