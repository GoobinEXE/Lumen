package dev.prism.lumen

import android.Manifest
import android.content.ContentValues
import android.content.pm.PackageManager
import android.provider.CalendarContract
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.TimeZone

class CalendarBridge(
    private val activity: MainActivity,
    private val requestPermissions: (MethodChannel.Result) -> Unit,
) : MethodChannel.MethodCallHandler {
    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, CHANNEL).setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "hasAccess" -> result.success(hasAccess())
            "requestAccess" -> requestPermissions(result)
            "createEvent" -> result.success(createEvent(call))
            else -> result.notImplemented()
        }
    }

    private fun hasAccess(): Boolean {
        val read = ContextCompat.checkSelfPermission(
            activity,
            Manifest.permission.READ_CALENDAR,
        ) == PackageManager.PERMISSION_GRANTED
        val write = ContextCompat.checkSelfPermission(
            activity,
            Manifest.permission.WRITE_CALENDAR,
        ) == PackageManager.PERMISSION_GRANTED
        return read && write
    }

    private fun createEvent(call: MethodCall): String? {
        if (!hasAccess()) return null
        val title = call.argument<String>("title") ?: return null
        val startMs = call.argument<Number>("startMs")?.toLong() ?: return null
        val endMs = call.argument<Number>("endMs")?.toLong() ?: return null
        val notes = call.argument<String>("notes")
        val calendarId = writableCalendarId() ?: return null

        val values = ContentValues().apply {
            put(CalendarContract.Events.CALENDAR_ID, calendarId)
            put(CalendarContract.Events.TITLE, title)
            put(CalendarContract.Events.DESCRIPTION, notes)
            put(CalendarContract.Events.DTSTART, startMs)
            put(CalendarContract.Events.DTEND, endMs)
            put(CalendarContract.Events.EVENT_TIMEZONE, TimeZone.getDefault().id)
        }
        val uri = activity.contentResolver.insert(CalendarContract.Events.CONTENT_URI, values)
        return uri?.lastPathSegment
    }

    private fun writableCalendarId(): Long? {
        val projection = arrayOf(CalendarContract.Calendars._ID)
        val selection = "${CalendarContract.Calendars.VISIBLE} = 1 AND " +
            "${CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL} >= ${CalendarContract.Calendars.CAL_ACCESS_CONTRIBUTOR}"
        activity.contentResolver.query(
            CalendarContract.Calendars.CONTENT_URI,
            projection,
            selection,
            null,
            null,
        )?.use { cursor ->
            if (!cursor.moveToFirst()) return null
            return cursor.getLong(0)
        }
        return null
    }

    companion object {
        const val CHANNEL = "dev.prism.lumen/calendar_bridge"
    }
}
