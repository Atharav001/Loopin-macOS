package com.atharav.loopin.data

import androidx.room.*
import com.atharav.loopin.model.TimesheetEntry
import kotlinx.coroutines.flow.Flow

@Dao
interface TimesheetDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertEntry(entry: TimesheetEntry)

    @Update
    suspend fun updateEntry(entry: TimesheetEntry)

    @Query("DELETE FROM timesheet_entries WHERE id = :id")
    suspend fun deleteEntry(id: String)

    @Query("SELECT * FROM timesheet_entries WHERE id = :id LIMIT 1")
    suspend fun getEntryById(id: String): TimesheetEntry?

    @Query("SELECT * FROM timesheet_entries ORDER BY startAt ASC")
    fun getAllEntries(): Flow<List<TimesheetEntry>>

    @Query("SELECT * FROM timesheet_entries WHERE (startAt >= :start AND startAt < :end) OR (endAt > :start AND endAt <= :end) ORDER BY startAt ASC")
    fun getEntriesInRange(start: Long, end: Long): Flow<List<TimesheetEntry>>

    @Query("SELECT * FROM timesheet_entries WHERE isSynced = 0 ORDER BY updatedAt ASC")
    suspend fun getPendingSyncEntries(): List<TimesheetEntry>

    @Query("UPDATE timesheet_entries SET isSynced = 1 WHERE id = :id")
    suspend fun markSynced(id: String)
}
