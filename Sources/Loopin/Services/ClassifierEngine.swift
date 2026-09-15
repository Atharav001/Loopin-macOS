import Foundation

// MARK: - ClassificationMatch
public struct ClassificationMatch: Equatable, Sendable {
    public var category: String
    public var subcategory: String?
    public var productivity: ProductivityType
    public var matchedPhrase: String?
    
    public init(category: String, subcategory: String? = nil, productivity: ProductivityType, matchedPhrase: String? = nil) {
        self.category = category
        self.subcategory = subcategory
        self.productivity = productivity
        self.matchedPhrase = matchedPhrase
    }
}

// MARK: - ClassifierEngine
public struct ClassifierEngine: Sendable {
    public static func classify(text: String, rules: [ClassificationRule]) -> ClassificationMatch? {
        let lowerText = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if lowerText.isEmpty { return nil }
        
        // Rules are sorted with longest phrase first
        let sortedRules = rules.sorted { $0.phrase.count > $1.phrase.count }
        
        for rule in sortedRules {
            let phrase = rule.phrase.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            if !phrase.isEmpty && lowerText.contains(phrase) {
                return ClassificationMatch(
                    category: rule.category,
                    subcategory: rule.subcategory,
                    productivity: rule.productivityType,
                    matchedPhrase: rule.phrase
                )
            }
        }
        
        return nil
    }
    
    public static func learnRule(for rawText: String, category: String, subcategory: String? = nil, productivity: ProductivityType, db: DatabaseManager = .shared) {
        let trimmed = rawText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return }
        
        // Check if there is already a rule for this phrase
        let rule = ClassificationRule(
            phrase: trimmed,
            category: category,
            subcategory: subcategory,
            productivity: productivity.rawValue
        )
        db.insertRule(rule)
    }
}
