package com.atharav.loopin.classifier

import com.atharav.loopin.model.ClassificationRule

data class ClassificationMatch(
    val category: String,
    val subcategory: String?,
    val productivity: String,
    val matchedPhrase: String
)

object ClassifierEngine {
    fun classify(text: String, rules: List<ClassificationRule>): ClassificationMatch? {
        val lower = text.trim().lowercase()
        if (lower.isEmpty()) return null

        // Longest phrase match first
        val sorted = rules.sortedByDescending { it.phrase.length }
        for (rule in sorted) {
            val p = rule.phrase.trim().lowercase()
            if (p.isNotEmpty() && lower.contains(p)) {
                return ClassificationMatch(
                    category = rule.category,
                    subcategory = rule.subcategory,
                    productivity = rule.productivity,
                    matchedPhrase = rule.phrase
                )
            }
        }
        return null
    }
}
