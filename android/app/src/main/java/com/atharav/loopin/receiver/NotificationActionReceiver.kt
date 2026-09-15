package com.atharav.loopin.receiver

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.app.RemoteInput
import com.atharav.loopin.classifier.ClassifierEngine
import com.atharav.loopin.data.LoopinDatabase
import com.atharav.loopin.model.TimesheetEntry
import com.atharav.loopin.service.HourlyLoggingService
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class NotificationActionReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val db = LoopinDatabase.getInstance(context)
        val now = System.currentTimeMillis()
        val oneHourAgo = now - 3600000L

        when (intent.action) {
            HourlyLoggingService.ACTION_REPLY -> {
                val bundle = RemoteInput.getResultsFromIntent(intent)
                val replyText = bundle?.getCharSequence(HourlyLoggingService.KEY_TEXT_REPLY)?.toString()

                if (!replyText.isNullOrBlank()) {
                    CoroutineScope(Dispatchers.IO).launch {
                        val rules = db.classificationDao().getAllRules()
                        val match = ClassifierEngine.classify(replyText, rules)

                        val entry = TimesheetEntry(
                            kind = "logged",
                            startAt = oneHourAgo,
                            endAt = now,
                            rawText = replyText,
                            inputMethod = "typed",
                            category = match?.category ?: "Deep Work",
                            subcategory = match?.subcategory,
                            productivity = match?.productivity ?: "productive",
                            deviceId = "android",
                            isSynced = false
                        )
                        db.timesheetDao().insertEntry(entry)
                    }
                }
            }

            HourlyLoggingService.ACTION_SKIP -> {
                CoroutineScope(Dispatchers.IO).launch {
                    val entry = TimesheetEntry(
                        kind = "logged",
                        startAt = oneHourAgo,
                        endAt = now,
                        rawText = "Skipped interval",
                        inputMethod = "skipped",
                        category = "Rest",
                        productivity = "neutral",
                        deviceId = "android",
                        isSynced = false
                    )
                    db.timesheetDao().insertEntry(entry)
                }
            }
        }
    }
}
