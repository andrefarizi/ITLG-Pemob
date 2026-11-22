package com.example.itlg_mobile

import android.Manifest
import android.content.ContentUris
import android.content.ContentValues
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.CalendarContract
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.TimeZone

class MainActivity : FlutterActivity() {
    companion object {
        private const val REQ_CALENDAR_PERMISSION = 4091
    }

    private var pendingCalendarPermResult: MethodChannel.Result? = null

    private fun isAndroidEmulator(): Boolean {
        return (Build.FINGERPRINT.startsWith("generic")
                || Build.FINGERPRINT.startsWith("unknown")
                || Build.FINGERPRINT.contains("emulator", ignoreCase = true)
                || Build.MODEL.contains("google_sdk")
                || Build.MODEL.contains("Emulator")
                || Build.MODEL.contains("Android SDK built for")
                || Build.MANUFACTURER.contains("Genymotion")
                || Build.HARDWARE.contains("goldfish")
                || Build.HARDWARE.contains("ranchu")
                || Build.PRODUCT.contains("sdk_gphone")
                || Build.PRODUCT.contains("emulator"))
    }

    private fun hasCalendarPermission(): Boolean {
        val readGranted = ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.READ_CALENDAR
        ) == PackageManager.PERMISSION_GRANTED
        val writeGranted = ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.WRITE_CALENDAR
        ) == PackageManager.PERMISSION_GRANTED
        return readGranted && writeGranted
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQ_CALENDAR_PERMISSION) {
            val granted = grantResults.isNotEmpty() &&
                grantResults.all { it == PackageManager.PERMISSION_GRANTED }
            pendingCalendarPermResult?.success(granted)
            pendingCalendarPermResult = null
        }
    }

    /**
     * Cari kalender yang bisa ditulisi pada perangkat, atau buat kalender lokal
     * "ITLG Mobile" jika emulator/HP belum memiliki akun kalender tersinkron.
     */
    private fun findOrCreateWritableCalendar(): Pair<Long, String>? {
        val projection = arrayOf(
            CalendarContract.Calendars._ID,
            CalendarContract.Calendars.CALENDAR_DISPLAY_NAME,
            CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL,
            CalendarContract.Calendars.IS_PRIMARY
        )
        var bestId: Long? = null
        var bestName = "Kalender Perangkat"
        var bestPrimary = false

        try {
            contentResolver.query(
                CalendarContract.Calendars.CONTENT_URI,
                projection,
                "${CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL} >= ?",
                arrayOf(CalendarContract.Calendars.CAL_ACCESS_CONTRIBUTOR.toString()),
                null
            )?.use { cursor ->
                while (cursor.moveToNext()) {
                    val id = cursor.getLong(0)
                    val name = cursor.getString(1) ?: "Kalender"
                    val isPrimary = cursor.getInt(3) == 1
                    if (bestId == null || (isPrimary && !bestPrimary)) {
                        bestId = id
                        bestName = name
                        bestPrimary = isPrimary
                    }
                }
            }
        } catch (_: Exception) {
        }

        if (bestId != null) {
            return Pair(bestId!!, bestName)
        }

        // Buat kalender lokal ITLG Mobile (bermanfaat pada emulator tanpa akun Google)
        return try {
            val syncUri: Uri = CalendarContract.Calendars.CONTENT_URI.buildUpon()
                .appendQueryParameter(CalendarContract.CALLER_IS_SYNCADAPTER, "true")
                .appendQueryParameter(CalendarContract.Calendars.ACCOUNT_NAME, "ITLG Mobile")
                .appendQueryParameter(
                    CalendarContract.Calendars.ACCOUNT_TYPE,
                    CalendarContract.ACCOUNT_TYPE_LOCAL
                )
                .build()

            val values = ContentValues().apply {
                put(CalendarContract.Calendars.ACCOUNT_NAME, "ITLG Mobile")
                put(CalendarContract.Calendars.ACCOUNT_TYPE, CalendarContract.ACCOUNT_TYPE_LOCAL)
                put(CalendarContract.Calendars.NAME, "Jadwal Praktikum ITLG")
                put(CalendarContract.Calendars.CALENDAR_DISPLAY_NAME, "Jadwal Praktikum ITLG")
                put(CalendarContract.Calendars.CALENDAR_COLOR, 0xFF991B1B.toInt())
                put(
                    CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL,
                    CalendarContract.Calendars.CAL_ACCESS_OWNER
                )
                put(CalendarContract.Calendars.OWNER_ACCOUNT, "ITLG Mobile")
                put(CalendarContract.Calendars.VISIBLE, 1)
                put(CalendarContract.Calendars.SYNC_EVENTS, 1)
                put(CalendarContract.Calendars.CALENDAR_TIME_ZONE, TimeZone.getDefault().id)
            }
            val inserted = contentResolver.insert(syncUri, values)
            val newId = inserted?.let { ContentUris.parseId(it) }
            if (newId != null && newId > 0) Pair(newId, "Jadwal Praktikum ITLG") else null
        } catch (_: Exception) {
            null
        }
    }

    private fun syncEventsToCalendar(events: List<Map<String, Any?>>): Map<String, Any> {
        if (!hasCalendarPermission()) {
            return mapOf("ok" to false, "reason" to "permission_denied", "count" to 0)
        }
        val cal = findOrCreateWritableCalendar()
            ?: return mapOf("ok" to false, "reason" to "no_calendar", "count" to 0)

        val (calendarId, calendarName) = cal
        val tzId = TimeZone.getDefault().id
        var synced = 0

        for (ev in events) {
            val syncId = (ev["id"] ?: "").toString()
            val title = (ev["title"] ?: "Praktikum ITLG").toString()
            val rawDesc = (ev["description"] ?: "").toString()
            val marker = "[ITLG-SYNC:$syncId]"
            val description = if (rawDesc.contains(marker)) rawDesc else "$rawDesc\n$marker".trim()
            val location = (ev["location"] ?: "Laboratorium Fasilkom-TI USU").toString()
            val startMillis = (ev["startMillis"] as? Number)?.toLong() ?: continue
            val endMillis = (ev["endMillis"] as? Number)?.toLong() ?: (startMillis + 100 * 60 * 1000L)
            val rrule = (ev["rrule"] as? String) ?: "FREQ=WEEKLY;COUNT=12"

            // Cek apakah event dengan marker ITLG-SYNC sudah ada agar tidak duplikat
            var existingEventId: Long? = null
            try {
                contentResolver.query(
                    CalendarContract.Events.CONTENT_URI,
                    arrayOf(CalendarContract.Events._ID),
                    "${CalendarContract.Events.CALENDAR_ID} = ? AND ${CalendarContract.Events.DESCRIPTION} LIKE ? AND ${CalendarContract.Events.DELETED} != 1",
                    arrayOf(calendarId.toString(), "%$marker%"),
                    null
                )?.use { cursor ->
                    if (cursor.moveToFirst()) {
                        existingEventId = cursor.getLong(0)
                    }
                }
            } catch (_: Exception) {
            }

            val values = ContentValues().apply {
                put(CalendarContract.Events.CALENDAR_ID, calendarId)
                put(CalendarContract.Events.TITLE, title)
                put(CalendarContract.Events.DESCRIPTION, description)
                put(CalendarContract.Events.EVENT_LOCATION, location)
                put(CalendarContract.Events.DTSTART, startMillis)
                put(CalendarContract.Events.EVENT_TIMEZONE, tzId)
                if (rrule.isNotEmpty()) {
                    val durMinutes = ((endMillis - startMillis) / 60000L).coerceAtLeast(30L)
                    put(CalendarContract.Events.DURATION, "P${durMinutes}M")
                    put(CalendarContract.Events.RRULE, rrule)
                    putNull(CalendarContract.Events.DTEND)
                } else {
                    put(CalendarContract.Events.DTEND, endMillis)
                }
            }

            try {
                if (existingEventId != null) {
                    val updateUri = ContentUris.withAppendedId(
                        CalendarContract.Events.CONTENT_URI,
                        existingEventId!!
                    )
                    contentResolver.update(updateUri, values, null, null)
                    synced++
                } else {
                    val insertedUri = contentResolver.insert(
                        CalendarContract.Events.CONTENT_URI,
                        values
                    )
                    val newEventId = insertedUri?.let { ContentUris.parseId(it) }
                    if (newEventId != null && newEventId > 0) {
                        val rem = ContentValues().apply {
                            put(CalendarContract.Reminders.EVENT_ID, newEventId)
                            put(CalendarContract.Reminders.MINUTES, 15)
                            put(
                                CalendarContract.Reminders.METHOD,
                                CalendarContract.Reminders.METHOD_ALERT
                            )
                        }
                        try {
                            contentResolver.insert(CalendarContract.Reminders.CONTENT_URI, rem)
                        } catch (_: Exception) {
                        }
                        synced++
                    }
                }
            } catch (_: Exception) {
            }
        }

        return mapOf(
            "ok" to (synced > 0),
            "count" to synced,
            "calendarName" to calendarName
        )
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.example.itlg_mobile/config")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getMapsApiKey" -> {
                        try {
                            val appInfo = packageManager.getApplicationInfo(
                                packageName,
                                PackageManager.GET_META_DATA
                            )
                            val key = appInfo.metaData?.getString("com.google.android.geo.API_KEY")
                            result.success(key)
                        } catch (e: Exception) {
                            result.success(null)
                        }
                    }
                    "isEmulator" -> {
                        result.success(isAndroidEmulator())
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.example.itlg_mobile/calendar")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "hasCalendarPermission" -> {
                        result.success(hasCalendarPermission())
                    }
                    "requestCalendarPermission" -> {
                        if (hasCalendarPermission()) {
                            result.success(true)
                        } else {
                            pendingCalendarPermResult?.success(false)
                            pendingCalendarPermResult = result
                            ActivityCompat.requestPermissions(
                                this,
                                arrayOf(
                                    Manifest.permission.READ_CALENDAR,
                                    Manifest.permission.WRITE_CALENDAR
                                ),
                                REQ_CALENDAR_PERMISSION
                            )
                        }
                    }
                    "syncSchedulesToCalendar" -> {
                        @Suppress("UNCHECKED_CAST")
                        val rawEvents = (call.arguments as? List<Map<String, Any?>>) ?: emptyList()
                        result.success(syncEventsToCalendar(rawEvents))
                    }
                    "openDeviceCalendar" -> {
                        try {
                            val timeMillis = (call.arguments as? Number)?.toLong()
                                ?: System.currentTimeMillis()
                            val builder = CalendarContract.CONTENT_URI.buildUpon()
                            builder.appendPath("time")
                            ContentUris.appendId(builder, timeMillis)
                            val intent = Intent(Intent.ACTION_VIEW).setData(builder.build())
                            startActivity(intent)
                            result.success(true)
                        } catch (_: Exception) {
                            result.success(false)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
