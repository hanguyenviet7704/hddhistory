package com.eup.meup

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Build
import androidx.core.app.NotificationChannelCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Android counterpart to iOS's `LiveActivityChannel.swift`.
 *
 * Renders the lesson "Live Update" — a promoted ongoing notification
 * (`NotificationCompat.ProgressStyle` + `setRequestPromotedOngoing`) that Android
 * 16 (API 36) surfaces on the status-bar chip, lock screen and always-on display,
 * the platform's Live-Activity equivalent.
 *
 * On Android < 16 every call is a graceful no-op (returns `false`): the Dart
 * [LiveActivityService] swallows that and the timed return-nudge notification
 * (which ships on every version) remains the only Android surface — matching the
 * agreed "iOS-rich, Android best-effort" scope.
 */
class LiveActivityChannel(context: Context, messenger: BinaryMessenger) {
    private val appContext: Context = context.applicationContext
    private val channel = MethodChannel(messenger, CHANNEL_NAME)

    companion object {
        private const val CHANNEL_NAME = "meup/live_activity"
        private const val NOTIFICATION_CHANNEL_ID = "meup_live_update_channel"
        private const val NOTIFICATION_ID = 0x4C55_5044 // "LUPD" — distinct from the return-nudge id
        // Live Updates (promoted ongoing + ProgressStyle) require Android 16 / API 36.
        private const val MIN_SDK_LIVE_UPDATE = 36
        private const val BRAND_COLOR = 0xFF9D50DD.toInt()
    }

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "start", "update" -> {
                    @Suppress("UNCHECKED_CAST")
                    result.success(postOrUpdate(call.arguments as? Map<String, Any?>))
                }
                "end" -> {
                    end()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun isSupported(): Boolean = Build.VERSION.SDK_INT >= MIN_SDK_LIVE_UPDATE

    private fun postOrUpdate(args: Map<String, Any?>?): Boolean {
        if (!isSupported() || args == null) return false

        val manager = NotificationManagerCompat.from(appContext)
        if (!manager.areNotificationsEnabled()) return false
        ensureChannel(manager)

        val progress = ((args["progress"] as? Double) ?: 0.0).coerceIn(0.0, 1.0)
        val pct = (progress * 100).toInt()
        val isDone = (args["isDone"] as? Boolean) ?: false
        val courseName = args["courseName"] as? String ?: ""
        val primaryNudge = args["primaryNudge"] as? String ?: ""
        val footerNudge = args["footerNudge"] as? String ?: ""
        val imagePath = args["courseImagePath"] as? String ?: ""

        val progressStyle = NotificationCompat.ProgressStyle()
            .setStyledByProgress(true)
            .setProgressSegments(
                listOf(NotificationCompat.ProgressStyle.Segment(100).setColor(BRAND_COLOR)),
            )
            .setProgress(pct)

        val builder = NotificationCompat.Builder(appContext, NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_meup)
            .setContentTitle(courseName)
            .setContentText(if (isDone) footerNudge else primaryNudge)
            .setShortCriticalText("$pct%")
            .setStyle(progressStyle)
            .setColor(BRAND_COLOR)
            .setColorized(false) // required for promoted ongoing notifications
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setRequestPromotedOngoing(true)
            .setContentIntent(launchIntent())

        // Course thumbnail as the large icon — the design's chosen "layout C".
        largeIcon(imagePath)?.let { builder.setLargeIcon(it) }

        return try {
            manager.notify(NOTIFICATION_ID, builder.build())
            true
        } catch (e: SecurityException) {
            false
        }
    }

    private fun end() {
        NotificationManagerCompat.from(appContext).cancel(NOTIFICATION_ID)
    }

    private fun largeIcon(path: String): Bitmap? {
        if (path.isEmpty()) return null
        val file = File(path)
        if (!file.exists()) return null
        return try {
            BitmapFactory.decodeFile(file.absolutePath)
        } catch (e: Exception) {
            null
        }
    }

    private fun launchIntent(): PendingIntent {
        val intent = appContext.packageManager
            .getLaunchIntentForPackage(appContext.packageName)
            ?.apply { flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP }
            ?: Intent()
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        return PendingIntent.getActivity(appContext, 0, intent, flags)
    }

    private fun ensureChannel(manager: NotificationManagerCompat) {
        if (manager.getNotificationChannelCompat(NOTIFICATION_CHANNEL_ID) != null) return
        val channel = NotificationChannelCompat.Builder(
            NOTIFICATION_CHANNEL_ID,
            // IMPORTANCE_MIN is disallowed for promoted notifications — use DEFAULT.
            NotificationManagerCompat.IMPORTANCE_DEFAULT,
        )
            .setName("Lesson progress")
            .setDescription("Ongoing lesson progress shown as a Live Update")
            .setShowBadge(false)
            .build()
        manager.createNotificationChannel(channel)
    }
}
