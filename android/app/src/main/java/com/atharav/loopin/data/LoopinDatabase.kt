package com.atharav.loopin.data

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import com.atharav.loopin.model.ClassificationRule
import com.atharav.loopin.model.TimesheetEntry

@Database(entities = [TimesheetEntry::class, ClassificationRule::class], version = 1, exportSchema = false)
abstract class LoopinDatabase : RoomDatabase() {
    abstract fun timesheetDao(): TimesheetDao
    abstract fun classificationDao(): ClassificationDao

    companion object {
        @Volatile
        private var INSTANCE: LoopinDatabase? = null

        fun getInstance(context: Context): LoopinDatabase {
            return INSTANCE ?: synchronized(this) {
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    LoopinDatabase::class.java,
                    "loopin_android.db"
                ).build()
                INSTANCE = instance
                instance
            }
        }
    }
}
