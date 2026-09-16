import SwiftUI

// MARK: - CategoryPreset
public struct CategoryPreset: Identifiable, Hashable, Sendable {
    public var id: String { name }
    public let name: String
    public let defaultProductivity: ProductivityType
    public let iconName: String
    public let colorHex: String
    
    public init(name: String, defaultProductivity: ProductivityType, iconName: String, colorHex: String) {
        self.name = name
        self.defaultProductivity = defaultProductivity
        self.iconName = iconName
        self.colorHex = colorHex
    }
    
    public static let defaults: [CategoryPreset] = [
        CategoryPreset(name: "Coding", defaultProductivity: .productive, iconName: "chevron.left.forwardslash.chevron.right", colorHex: "#6366F1"),
        CategoryPreset(name: "Engineering", defaultProductivity: .productive, iconName: "cpu", colorHex: "#3B82F6"),
        CategoryPreset(name: "Design", defaultProductivity: .productive, iconName: "paintpalette", colorHex: "#EC4899"),
        CategoryPreset(name: "Meeting", defaultProductivity: .productive, iconName: "person.2", colorHex: "#8B5CF6"),
        CategoryPreset(name: "Research", defaultProductivity: .productive, iconName: "book", colorHex: "#10B981"),
        CategoryPreset(name: "Email & Admin", defaultProductivity: .productive, iconName: "envelope", colorHex: "#64748B"),
        CategoryPreset(name: "Planning", defaultProductivity: .productive, iconName: "calendar", colorHex: "#A855F7"),
        CategoryPreset(name: "Meals & Lunch", defaultProductivity: .wasteful, iconName: "fork.knife", colorHex: "#F59E0B"),
        CategoryPreset(name: "Personal Errands", defaultProductivity: .wasteful, iconName: "cart.fill", colorHex: "#F97316"),
        CategoryPreset(name: "Break", defaultProductivity: .wasteful, iconName: "cup.and.saucer", colorHex: "#EAB308"),
        CategoryPreset(name: "Social Media", defaultProductivity: .wasteful, iconName: "globe", colorHex: "#EF4444"),
        CategoryPreset(name: "YouTube Watching", defaultProductivity: .wasteful, iconName: "play.rectangle", colorHex: "#DC2626"),
        CategoryPreset(name: "Gaming", defaultProductivity: .wasteful, iconName: "gamecontroller", colorHex: "#E11D48"),
        CategoryPreset(name: "Other", defaultProductivity: .wasteful, iconName: "tag", colorHex: "#94A3B8")
    ]
}

public extension Color {
    @MainActor
    static func forProductivity(_ prod: ProductivityType?) -> Color {
        guard let p = prod else { return Theme.wasteful }
        switch p {
        case .productive: return Theme.productive
        case .wasteful, .neutral: return Theme.wasteful
        }
    }
    
    @MainActor
    static func forCategory(_ categoryName: String?) -> Color {
        guard let cat = categoryName else { return Theme.textMuted }
        if let preset = CategoryPreset.defaults.first(where: { $0.name.lowercased() == cat.lowercased() }) {
            return Color.forProductivity(preset.defaultProductivity)
        }
        return Theme.accent
    }
}
