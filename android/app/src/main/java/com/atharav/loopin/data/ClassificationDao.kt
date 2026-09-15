package com.atharav.loopin.data

import androidx.room.*
import com.atharav.loopin.model.ClassificationRule
import kotlinx.coroutines.flow.Flow

@Dao
interface ClassificationDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertRule(rule: ClassificationRule)

    @Delete
    suspend fun deleteRule(rule: ClassificationRule)

    @Query("SELECT * FROM classification_rules ORDER BY LENGTH(phrase) DESC")
    suspend fun getAllRules(): List<ClassificationRule>

    @Query("SELECT * FROM classification_rules ORDER BY LENGTH(phrase) DESC")
    fun getAllRulesFlow(): Flow<List<ClassificationRule>>
}
