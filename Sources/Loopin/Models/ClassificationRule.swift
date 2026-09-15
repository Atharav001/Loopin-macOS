import Foundation

// MARK: - ClassificationRule
public struct ClassificationRule: Identifiable, Codable, Equatable, Sendable {
    public var id: String
    public var phrase: String
    public var category: String
    public var subcategory: String?
    public var productivity: String // "productive" | "neutral" | "wasteful"
    public var updatedAt: Date
    
    public init(
        id: String = UUID().uuidString,
        phrase: String,
        category: String,
        subcategory: String? = nil,
        productivity: String = ProductivityType.productive.rawValue,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.phrase = phrase.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        self.category = category.trimmingCharacters(in: .whitespacesAndNewlines)
        self.subcategory = subcategory?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.productivity = productivity
        self.updatedAt = updatedAt
    }
    
    public var productivityType: ProductivityType {
        return ProductivityType(rawValue: productivity) ?? .productive
    }
}
