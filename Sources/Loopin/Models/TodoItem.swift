import SwiftUI

// MARK: - TodoItem
public struct TodoItem: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var title: String
    public var isCompleted: Bool
    public var isStarred: Bool
    public var createdAt: Date
    public var completedAt: Date?
    public var orderIndex: Int
    
    public init(
        id: UUID = UUID(),
        title: String,
        isCompleted: Bool = false,
        isStarred: Bool = false,
        createdAt: Date = Date(),
        completedAt: Date? = nil,
        orderIndex: Int = 0
    ) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.isStarred = isStarred
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.orderIndex = orderIndex
    }
}

// MARK: - TodoFilter
public enum TodoFilter: String, CaseIterable, Identifiable, Codable, Sendable {
    case all = "All"
    case active = "Active"
    case starred = "Starred"
    case completed = "Done"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .all: return "tray.full.fill"
        case .active: return "circle.dashed"
        case .starred: return "star.fill"
        case .completed: return "checkmark.circle.fill"
        }
    }
}

// MARK: - TodoPaneTheme
public enum TodoPaneTheme: String, CaseIterable, Identifiable, Codable, Sendable {
    case stickyAmber = "Sticky Amber"
    case obsidian = "Obsidian OLED"
    case cyberEmerald = "Cyber Mint"
    case royalViolet = "Royal Violet"
    case sunsetCoral = "Sunset Coral"
    case oceanAzure = "Ocean Azure"
    case darkSlate = "Dark Slate"
    
    public var id: String { rawValue }
    
    public var displayName: String { rawValue }
    
    public var swatchColor: Color {
        switch self {
        case .stickyAmber: return Color(red: 245/255, green: 158/255, blue: 11/255)
        case .obsidian: return Color(red: 220/255, green: 225/255, blue: 235/255)
        case .cyberEmerald: return Color(red: 16/255, green: 185/255, blue: 129/255)
        case .royalViolet: return Color(red: 139/255, green: 92/255, blue: 246/255)
        case .sunsetCoral: return Color(red: 244/255, green: 63/255, blue: 94/255)
        case .oceanAzure: return Color(red: 2/255, green: 136/255, blue: 235/255)
        case .darkSlate: return Color(red: 100/255, green: 116/255, blue: 139/255)
        }
    }
    
    public var accent: Color {
        swatchColor
    }
    
    public var accentLight: Color {
        switch self {
        case .stickyAmber: return Color(red: 251/255, green: 191/255, blue: 36/255)
        case .obsidian: return Color(red: 240/255, green: 242/255, blue: 245/255)
        case .cyberEmerald: return Color(red: 52/255, green: 211/255, blue: 153/255)
        case .royalViolet: return Color(red: 167/255, green: 139/255, blue: 250/255)
        case .sunsetCoral: return Color(red: 251/255, green: 113/255, blue: 133/255)
        case .oceanAzure: return Color(red: 56/255, green: 189/255, blue: 248/255)
        case .darkSlate: return Color(red: 148/255, green: 163/255, blue: 184/255)
        }
    }
    
    public var bgCanvasTop: Color {
        switch self {
        case .stickyAmber: return Color(red: 28/255, green: 21/255, blue: 10/255)
        case .obsidian: return Color(red: 8/255, green: 9/255, blue: 11/255)
        case .cyberEmerald: return Color(red: 10/255, green: 26/255, blue: 20/255)
        case .royalViolet: return Color(red: 22/255, green: 16/255, blue: 34/255)
        case .sunsetCoral: return Color(red: 28/255, green: 14/255, blue: 18/255)
        case .oceanAzure: return Color(red: 10/255, green: 20/255, blue: 32/255)
        case .darkSlate: return Color(red: 15/255, green: 18/255, blue: 24/255)
        }
    }
    
    public var bgCanvasBottom: Color {
        switch self {
        case .stickyAmber: return Color(red: 16/255, green: 12/255, blue: 7/255)
        case .obsidian: return Color(red: 5/255, green: 6/255, blue: 7/255)
        case .cyberEmerald: return Color(red: 7/255, green: 16/255, blue: 13/255)
        case .royalViolet: return Color(red: 14/255, green: 10/255, blue: 22/255)
        case .sunsetCoral: return Color(red: 18/255, green: 8/255, blue: 11/255)
        case .oceanAzure: return Color(red: 7/255, green: 14/255, blue: 22/255)
        case .darkSlate: return Color(red: 10/255, green: 12/255, blue: 16/255)
        }
    }
    
    public var cardBg: Color {
        switch self {
        case .stickyAmber: return Color(red: 38/255, green: 28/255, blue: 14/255).opacity(0.85)
        case .obsidian: return Color(red: 18/255, green: 20/255, blue: 24/255).opacity(0.85)
        case .cyberEmerald: return Color(red: 14/255, green: 34/255, blue: 27/255).opacity(0.85)
        case .royalViolet: return Color(red: 30/255, green: 22/255, blue: 46/255).opacity(0.85)
        case .sunsetCoral: return Color(red: 38/255, green: 18/255, blue: 24/255).opacity(0.85)
        case .oceanAzure: return Color(red: 14/255, green: 28/255, blue: 44/255).opacity(0.85)
        case .darkSlate: return Color(red: 22/255, green: 27/255, blue: 36/255).opacity(0.85)
        }
    }
    
    public var cardHover: Color {
        cardBg.opacity(0.95)
    }
    
    public var borderStroke: Color {
        accent.opacity(0.25)
    }
    
    public var glowColor: Color {
        accent.opacity(0.3)
    }
}
