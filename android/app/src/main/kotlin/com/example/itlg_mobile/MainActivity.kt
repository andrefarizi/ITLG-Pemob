package com.example.itlg_mobile

import android.Manifest
import android.app.Activity
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.ContentUris
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.provider.CalendarContract
import android.provider.MediaStore
import android.provider.OpenableColumns
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.util.TimeZone

class MainActivity : FlutterActivity() {
    companion object {
        private const val REQ_CALENDAR_PERMISSION = 4091
        private const val REQ_PICK_FILE = 4092
        private const val REQ_NOTIFICATION_PERMISSION = 4093
        private const val NOTIF_CHANNEL_ID = "itlg_push_alerts"
        private const val EXTRA_OPEN_NOTIFICATIONS = "itlg_open_notifications"
    }

    private var pendingCalendarPermResult: MethodChannel.Result? = null
    private var pendingFilePickResult: MethodChannel.Result? = null
    private var pendingNotificationPermResult: MethodChannel.Result? = null
    private var notificationChannel: MethodChannel? = null
    private var pendingNotificationTap: Boolean = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        ensureNotificationChannel()
        if (intent?.getBooleanExtra(EXTRA_OPEN_NOTIFICATIONS, false) == true) {
            pendingNotificationTap = true
            intent?.removeExtra(EXTRA_OPEN_NOTIFICATIONS)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (intent.getBooleanExtra(EXTRA_OPEN_NOTIFICATIONS, false)) {
            intent.removeExtra(EXTRA_OPEN_NOTIFICATIONS)
            val ch = notificationChannel
            if (ch != null) {
                ch.invokeMethod("onNotificationTapped", null)
            } else {
                pendingNotificationTap = true
            }
        }
    }

    private fun ensureNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val mgr = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val channel = NotificationChannel(
                NOTIF_CHANNEL_ID,
                "Notifikasi ITLG Mobile",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Pemberitahuan presensi, jadwal, tugas, nilai, dan laboratorium"
                enableVibration(true)
                enableLights(true)
                lightColor = 0xFF850909.toInt()
            }
            mgr.createNotificationChannel(channel)
        }
    }

    private fun hasNotificationPermission(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            return ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.POST_NOTIFICATIONS
            ) == PackageManager.PERMISSION_GRANTED
        }
        return NotificationManagerCompat.from(this).areNotificationsEnabled()
    }

    private fun showDeviceNotification(notifId: Int, title: String, body: String): Boolean {
        if (!hasNotificationPermission()) return false
        return try {
            ensureNotificationChannel()
            val tapIntent = Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra(EXTRA_OPEN_NOTIFICATIONS, true)
            }
            val pendingFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
            val contentIntent = PendingIntent.getActivity(this, notifId, tapIntent, pendingFlags)

            val largeIcon = BitmapFactory.decodeResource(resources, R.drawable.ic_notif_large)
            val notification = NotificationCompat.Builder(this, NOTIF_CHANNEL_ID)
                .setSmallIcon(R.drawable.ic_stat_itlg)
                .setLargeIcon(largeIcon)
                .setColor(0xFF0E2C48.toInt())
                .setContentTitle(title)
                .setContentText(body)
                .setStyle(NotificationCompat.BigTextStyle().bigText(body))
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setCategory(NotificationCompat.CATEGORY_MESSAGE)
                .setDefaults(NotificationCompat.DEFAULT_ALL)
                .setAutoCancel(true)
                .setContentIntent(contentIntent)
                .build()

            NotificationManagerCompat.from(this).notify(notifId, notification)
            true
        } catch (_: SecurityException) {
            false
        } catch (_: Exception) {
            false
        }
    }

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
        } else if (requestCode == REQ_NOTIFICATION_PERMISSION) {
            val granted = grantResults.isNotEmpty() &&
                grantResults.all { it == PackageManager.PERMISSION_GRANTED }
            pendingNotificationPermResult?.success(granted)
            pendingNotificationPermResult = null
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQ_PICK_FILE) {
            val pending = pendingFilePickResult
            pendingFilePickResult = null
            if (pending == null) return

            if (resultCode != Activity.RESULT_OK || data?.data == null) {
                pending.success(null)
                return
            }

            val uri = data.data!!
            try {
                var displayName = "berkas_${System.currentTimeMillis()}"
                var sizeBytes = -1L
                contentResolver.query(uri, null, null, null, null)?.use { cursor ->
                    val nameIdx = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                    val sizeIdx = cursor.getColumnIndex(OpenableColumns.SIZE)
                    if (cursor.moveToFirst()) {
                        if (nameIdx >= 0) {
                            val n = cursor.getString(nameIdx)
                            if (!n.isNullOrBlank()) displayName = n
                        }
                        if (sizeIdx >= 0 && !cursor.isNull(sizeIdx)) {
                            sizeBytes = cursor.getLong(sizeIdx)
                        }
                    }
                }

                val mimeType = contentResolver.getType(uri) ?: "application/octet-stream"
                val safeName = displayName.replace(Regex("[^a-zA-Z0-9._-]"), "_")
                val uploadDir = File(cacheDir, "itlg_uploads")
                if (!uploadDir.exists()) uploadDir.mkdirs()
                val outFile = File(uploadDir, "${System.currentTimeMillis()}_$safeName")

                contentResolver.openInputStream(uri)?.use { input ->
                    FileOutputStream(outFile).use { output ->
                        input.copyTo(output)
                    }
                }
                if (sizeBytes <= 0L) sizeBytes = outFile.length()

                pending.success(
                    mapOf(
                        "name" to displayName,
                        "path" to outFile.absolutePath,
                        "size" to sizeBytes,
                        "mimeType" to mimeType
                    )
                )
            } catch (_: Exception) {
                pending.success(null)
            }
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

    private fun saveFileToDeviceDownloads(
        fileName: String,
        mimeType: String,
        bytes: ByteArray
    ): Map<String, Any> {
        val safeName = fileName.replace(Regex("[^a-zA-Z0-9._\\- ]"), "_").trim()
            .ifEmpty { "berkas_itlg_${System.currentTimeMillis()}.pdf" }
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val values = ContentValues().apply {
                    put(MediaStore.Downloads.DISPLAY_NAME, safeName)
                    put(MediaStore.Downloads.MIME_TYPE, mimeType)
                    put(
                        MediaStore.Downloads.RELATIVE_PATH,
                        "${Environment.DIRECTORY_DOWNLOADS}/ITLG Mobile"
                    )
                    put(MediaStore.Downloads.IS_PENDING, 1)
                }
                val resolver = contentResolver
                val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                    ?: throw IllegalStateException("Gagal membuat entri MediaStore.Downloads")
                resolver.openOutputStream(uri)?.use { out ->
                    out.write(bytes)
                    out.flush()
                } ?: throw IllegalStateException("Gagal membuka output stream")
                values.clear()
                values.put(MediaStore.Downloads.IS_PENDING, 0)
                resolver.update(uri, values, null, null)

                mapOf(
                    "ok" to true,
                    "fileName" to safeName,
                    "location" to "Download/ITLG Mobile/$safeName",
                    "uri" to uri.toString(),
                    "size" to bytes.size
                )
            } else {
                @Suppress("DEPRECATION")
                val baseDir = Environment.getExternalStoragePublicDirectory(
                    Environment.DIRECTORY_DOWNLOADS
                )
                val targetDir = File(baseDir, "ITLG Mobile")
                if (!targetDir.exists()) targetDir.mkdirs()
                val outFile = File(targetDir, safeName)
                FileOutputStream(outFile).use { out ->
                    out.write(bytes)
                    out.flush()
                }
                mapOf(
                    "ok" to true,
                    "fileName" to safeName,
                    "location" to outFile.absolutePath,
                    "uri" to Uri.fromFile(outFile).toString(),
                    "size" to bytes.size
                )
            }
        } catch (e: Exception) {
            try {
                val fallbackDir = getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS) ?: filesDir
                val outFile = File(fallbackDir, safeName)
                FileOutputStream(outFile).use { out ->
                    out.write(bytes)
                    out.flush()
                }
                mapOf(
                    "ok" to true,
                    "fileName" to safeName,
                    "location" to outFile.absolutePath,
                    "uri" to Uri.fromFile(outFile).toString(),
                    "size" to bytes.size
                )
            } catch (err: Exception) {
                mapOf(
                    "ok" to false,
                    "error" to (err.message ?: e.message ?: "Gagal menyimpan berkas")
                )
            }
        }
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

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.example.itlg_mobile/files")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pickFile" -> {
                        val imagesOnly = (call.arguments as? Map<*, *>)?.get("imagesOnly") as? Boolean ?: false
                        pendingFilePickResult?.success(null)
                        pendingFilePickResult = result
                        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                            addCategory(Intent.CATEGORY_OPENABLE)
                            type = if (imagesOnly) "image/*" else "*/*"
                        }
                        try {
                            @Suppress("DEPRECATION")
                            startActivityForResult(intent, REQ_PICK_FILE)
                        } catch (_: Exception) {
                            val fallback = Intent(Intent.ACTION_GET_CONTENT).apply {
                                addCategory(Intent.CATEGORY_OPENABLE)
                                type = if (imagesOnly) "image/*" else "*/*"
                            }
                            try {
                                @Suppress("DEPRECATION")
                                startActivityForResult(fallback, REQ_PICK_FILE)
                            } catch (_: Exception) {
                                pendingFilePickResult = null
                                result.success(null)
                            }
                        }
                    }
                    "saveToDownloads" -> {
                        val args = call.arguments as? Map<*, *>
                        val fileName = (args?.get("fileName") as? String) ?: "dokumen_itlg.pdf"
                        val mimeType = (args?.get("mimeType") as? String) ?: "application/octet-stream"
                        val bytes = (args?.get("bytes") as? ByteArray) ?: ByteArray(0)
                        result.success(saveFileToDeviceDownloads(fileName, mimeType, bytes))
                    }
                    else -> result.notImplemented()
                }
            }

        val notifCh = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.example.itlg_mobile/notifications")
        notificationChannel = notifCh
        notifCh.setMethodCallHandler { call, result ->
            when (call.method) {
                "hasNotificationPermission" -> {
                    result.success(hasNotificationPermission())
                }
                "requestNotificationPermission" -> {
                    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU || hasNotificationPermission()) {
                        result.success(hasNotificationPermission())
                    } else {
                        pendingNotificationPermResult?.success(false)
                        pendingNotificationPermResult = result
                        ActivityCompat.requestPermissions(
                            this,
                            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                            REQ_NOTIFICATION_PERMISSION
                        )
                    }
                }
                "consumeInitialTap" -> {
                    val tapped = pendingNotificationTap
                    pendingNotificationTap = false
                    result.success(tapped)
                }
                "showNotification" -> {
                    val args = call.arguments as? Map<*, *>
                    val id = (args?.get("id") as? Number)?.toInt() ?: (System.currentTimeMillis() and 0x7fffffff).toInt()
                    val title = (args?.get("title") as? String) ?: "ITLG Mobile"
                    val body = (args?.get("body") as? String) ?: ""
                    result.success(showDeviceNotification(id, title, body))
                }
                else -> result.notImplemented()
            }
        }
    }
}
