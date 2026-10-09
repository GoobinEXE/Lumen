package dev.prism.lumen

import android.Manifest
import android.content.pm.PackageManager
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private var pendingCalendarResult: MethodChannel.Result? = null

    private val calendarPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions(),
    ) { grants ->
        val ok = grants[Manifest.permission.READ_CALENDAR] == true &&
            grants[Manifest.permission.WRITE_CALENDAR] == true
        pendingCalendarResult?.success(ok)
        pendingCalendarResult = null
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        CalendarBridge(this) { result ->
            val read = ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.READ_CALENDAR,
            ) == PackageManager.PERMISSION_GRANTED
            val write = ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.WRITE_CALENDAR,
            ) == PackageManager.PERMISSION_GRANTED
            if (read && write) {
                result.success(true)
            } else if (pendingCalendarResult != null) {
                result.success(false)
            } else {
                pendingCalendarResult = result
                calendarPermissionLauncher.launch(
                    arrayOf(
                        Manifest.permission.READ_CALENDAR,
                        Manifest.permission.WRITE_CALENDAR,
                    ),
                )
            }
        }.register(flutterEngine.dartExecutor.binaryMessenger)
        SystemSettingsBridge(this).register(flutterEngine.dartExecutor.binaryMessenger)
        SamsungHealthBridge(this).register(flutterEngine.dartExecutor.binaryMessenger)
    }
}
