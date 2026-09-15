package com.atharav.loopin.service

import android.app.*
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import androidx.core.app.RemoteInput
import com.atharav.loopin.receiver.NotificationActionReceiver

class HourlyLoggingService : Service() {

    companion object {
        const val CHANNEL_ID = "loopin_hourly_prompts"
        const val NOTIFICATION_ID = 1001
        const val KEY_TEXT_REPLY = "key_text_reply"
        const val ACTION_REPLY = "com.atharav.loopin.ACTION_REPLY_LOG"
        const val ACTION_SKIP = "com.atharav.loopin.ACTION_SKIP_LOG"

        fun startService(context: Context) {
            val intent = Intent(context, HourlyLoggingService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val notification = buildHourlyPromptNotification("What did you work on in the past hour?")
        startForeground(NOTIFICATION_ID, notification)
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Hourly Activity Prompts",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Periodic interval prompts to log your recent activity"
                enableLights(true)
                enableVibration(true)
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun buildHourlyPromptNotification(content: String): Notification {
        // RemoteInput for inline typing reply
        val remoteInput = RemoteInput.Builder(KEY_TEXT_REPLY)
            .setLabel("Type what you did (e.g. Coding, Watching YouTube)...")
            .build()

        val replyIntent = Intent(this, NotificationActionReceiver::class.java).apply {
            action = ACTION_REPLY
        }
        val replyPendingIntent = PendingIntent.getBroadcast(
            this,
            0,
            replyIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
        )

        val replyAction = NotificationCompat.Action.Builder(
            android.R.drawable.ic_menu_send,
            "Log Activity",
            replyPendingIntent
        ).addRemoteInput(remoteInput).build()

        // Skip Action
        val skipIntent = Intent(this, NotificationActionReceiver::class.java).apply {
            action = ACTION_SKIP
        }
        val skipPendingIntent = PendingIntent.getBroadcast(
            this,
            1,
            skipIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val skipAction = NotificationCompat.Action.Builder(
            android.R.drawable.ic_media_next,
            "Skip",
            skipPendingIntent
        ).build()

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle("Loopin • Time to Log")
            .setContentText(content)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setOngoing(true) // Foreground persistent prompt like Tocklog
            .addAction(replyAction)
            .addAction(skipAction)
            .build()
    }
}
