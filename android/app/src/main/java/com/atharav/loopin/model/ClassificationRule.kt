package com.atharav.loopin.model

import androidx.room.Entity
import androidx.room.PrimaryKey
import java.util.UUID

@Entity(tableName = "classification_rules")
data class ClassificationRule(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val phrase: String,
    val category: String,
    val subcategory: String? = null,
    val productivity: String = "productive",
    val updatedAt: Long = System.currentTimeMillis()
)
