package com.atharav.loopin.classifier

import com.atharav.loopin.model.ClassificationRule

data class ClassificationMatch(
    val category: String,
    val subcategory: String?,
    val productivity: String,
    val matchedPhrase: String
)

    private val builtInTaxonomy = listOf(
        ClassificationMatch("Rest & Leisure", "Idle", "wasteful", "nothing"),
        ClassificationMatch("Rest & Leisure", "Idle", "wasteful", "doing nothing"),
        ClassificationMatch("Rest & Leisure", "Idle", "wasteful", "did nothing"),
        ClassificationMatch("Rest & Leisure", "Idle", "wasteful", "chutiyap"),
        ClassificationMatch("Rest & Leisure", "Idle", "wasteful", "chutiyapa"),
        ClassificationMatch("Rest & Leisure", "Idle", "wasteful", "bakchodi"),
        ClassificationMatch("Rest & Leisure", "Idle", "wasteful", "timepass"),
        ClassificationMatch("Rest & Leisure", "Idle", "wasteful", "time pass"),
        ClassificationMatch("Rest & Leisure", "Relaxation", "wasteful", "chill"),
        ClassificationMatch("Rest & Leisure", "Relaxation", "wasteful", "chilling"),
        ClassificationMatch("Rest & Leisure", "Idle", "wasteful", "wasted"),
        ClassificationMatch("Rest & Leisure", "Idle", "wasteful", "idle"),
        ClassificationMatch("Rest & Meals", "Meals", "wasteful", "lunch"),
        ClassificationMatch("Rest & Meals", "Meals", "wasteful", "dinner"),
        ClassificationMatch("Rest & Meals", "Meals", "wasteful", "breakfast"),
        ClassificationMatch("Personal Errands", "Groceries", "wasteful", "big basket"),
        ClassificationMatch("Personal Errands", "Groceries", "wasteful", "blinkit"),
        ClassificationMatch("Personal Errands", "Groceries", "wasteful", "zepto"),
        ClassificationMatch("Personal Errands", "Groceries", "wasteful", "grocery"),
        ClassificationMatch("Social Scrolling", "Reels", "wasteful", "reels"),
        ClassificationMatch("Social Scrolling", "Feed", "wasteful", "scrolling"),
        ClassificationMatch("Deep Work", "Coding", "productive", "coding"),
        ClassificationMatch("Deep Work", "Coding", "productive", "programming"),
        ClassificationMatch("Deep Work", "Debugging", "productive", "debug"),
        ClassificationMatch("Meetings", "Team Call", "productive", "meeting")
    )

    fun classify(text: String, rules: List<ClassificationRule>): ClassificationMatch? {
        val lower = text.trim().lowercase()
        if (lower.isEmpty()) return null

        // 1. Check user-defined rules from database (longest first)
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

        // 2. Built-in structured taxonomy
        for (rule in builtInTaxonomy) {
            if (lower.contains(rule.matchedPhrase)) {
                return rule
            }
        }

        // 3. Fallback: default to Non-Productive (Personal / Uncategorized)
        return ClassificationMatch(
            category = "Personal / Uncategorized",
            subcategory = null,
            productivity = "wasteful",
            matchedPhrase = text
        )
    }
}
