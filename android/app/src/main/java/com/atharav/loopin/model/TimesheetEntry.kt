package com.atharav.loopin.model

import androidx.room.Entity
import androidx.room.PrimaryKey
import java.util.UUID

@Entity(tableName = "timesheet_entries")
data class TimesheetEntry(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val kind: String = "logged", // "planned" | "logged"
    val startAt: Long,          // Epoch millis
    val endAt: Long,            // Epoch millis
    val rawText: String,
    val inputMethod: String = "typed", // "typed" | "voice" | "skipped"
    val category: String? = null,
    val subcategory: String? = null,
    val productivity: String? = "productive", // "productive" | "neutral" | "wasteful"
    val gcalEventId: String? = null,
    val deviceId: String = "android",
    val isSynced: Boolean = false,
    val updatedAt: Long = System.currentTimeMillis()
) {
    val durationMinutes: Int
        get() = ((endAt - startAt) / 60000).toInt().coerceAtLeast(0)

    val formattedDuration: String
        get() {
            val mins = durationMinutes
            val hrs = mins / 60
            val rem = mins % 60
            return if (hrs == 0) "${mins}m" else if (rem == 0) "${hrs}h" else "${hrs}h ${rem}m"
        }
}
