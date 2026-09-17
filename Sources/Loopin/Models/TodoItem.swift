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
    case stickyAmber = "Honey Gold"
    case obsidian = "Midnight OLED"
    case cyberEmerald = "Cyber Mint"
    case royalViolet = "Electric Violet"
    case sunsetCoral = "Sunset Rose"
    case oceanAzure = "Electric Azure"
    case darkSlate = "Titanium Slate"
    
    public var id: String { rawValue }
    
    public var displayName: String { rawValue }
    
    public var swatchColor: Color {
        switch self {
        case .stickyAmber: return Color(red: 245/255, green: 158/255, blue: 11/255)
        case .obsidian: return Color(red: 226/255, green: 232/255, blue: 240/255)
        case .cyberEmerald: return Color(red: 16/255, green: 185/255, blue: 129/255)
        case .royalViolet: return Color(red: 139/255, green: 92/255, blue: 246/255)
        case .sunsetCoral: return Color(red: 244/255, green: 63/255, blue: 94/255)
        case .oceanAzure: return Color(red: 14/255, green: 165/255, blue: 233/255)
        case .darkSlate: return Color(red: 100/255, green: 116/255, blue: 139/255)
        }
    }
    
    public var accent: Color {
        swatchColor
    }
    
    public var accentLight: Color {
        switch self {
        case .stickyAmber: return Color(red: 252/255, green: 211/255, blue: 77/255)
        case .obsidian: return Color(red: 248/255, green: 250/255, blue: 252/255)
        case .cyberEmerald: return Color(red: 110/255, green: 231/255, blue: 183/255)
        case .royalViolet: return Color(red: 196/255, green: 181/255, blue: 253/255)
        case .sunsetCoral: return Color(red: 253/255, green: 164/255, blue: 175/255)
        case .oceanAzure: return Color(red: 56/255, green: 189/255, blue: 248/255)
        case .darkSlate: return Color(red: 148/255, green: 163/255, blue: 184/255)
        }
    }
    
    public var bgCanvasTop: Color {
        switch self {
        case .stickyAmber: return Color(red: 28/255, green: 20/255, blue: 9/255)
        case .obsidian: return Color(red: 11/255, green: 12/255, blue: 15/255)
        case .cyberEmerald: return Color(red: 9/255, green: 28/255, blue: 22/255)
        case .royalViolet: return Color(red: 21/255, green: 14/255, blue: 38/255)
        case .sunsetCoral: return Color(red: 32/255, green: 12/255, blue: 19/255)
        case .oceanAzure: return Color(red: 8/255, green: 24/255, blue: 38/255)
        case .darkSlate: return Color(red: 15/255, green: 19/255, blue: 26/255)
        }
    }
    
    public var bgCanvasBottom: Color {
        switch self {
        case .stickyAmber: return Color(red: 14/255, green: 10/255, blue: 5/255)
        case .obsidian: return Color(red: 6/255, green: 7/255, blue: 9/255)
        case .cyberEmerald: return Color(red: 5/255, green: 15/255, blue: 12/255)
        case .royalViolet: return Color(red: 12/255, green: 8/255, blue: 22/255)
        case .sunsetCoral: return Color(red: 18/255, green: 6/255, blue: 10/255)
        case .oceanAzure: return Color(red: 5/255, green: 13/255, blue: 22/255)
        case .darkSlate: return Color(red: 9/255, green: 11/255, blue: 16/255)
        }
    }
    
    public var cardBg: Color {
        switch self {
        case .stickyAmber: return Color(red: 40/255, green: 30/255, blue: 14/255).opacity(0.8)
        case .obsidian: return Color(red: 22/255, green: 24/255, blue: 29/255).opacity(0.85)
        case .cyberEmerald: return Color(red: 14/255, green: 38/255, blue: 30/255).opacity(0.8)
        case .royalViolet: return Color(red: 32/255, green: 22/255, blue: 52/255).opacity(0.8)
        case .sunsetCoral: return Color(red: 42/255, green: 18/255, blue: 26/255).opacity(0.8)
        case .oceanAzure: return Color(red: 14/255, green: 32/255, blue: 50/255).opacity(0.8)
        case .darkSlate: return Color(red: 24/255, green: 29/255, blue: 38/255).opacity(0.85)
        }
    }
    
    public var cardHover: Color {
        switch self {
        case .stickyAmber: return Color(red: 54/255, green: 40/255, blue: 18/255)
        case .obsidian: return Color(red: 30/255, green: 33/255, blue: 40/255)
        case .cyberEmerald: return Color(red: 20/255, green: 50/255, blue: 40/255)
        case .royalViolet: return Color(red: 44/255, green: 30/255, blue: 70/255)
        case .sunsetCoral: return Color(red: 56/255, green: 24/255, blue: 35/255)
        case .oceanAzure: return Color(red: 20/255, green: 44/255, blue: 68/255)
        case .darkSlate: return Color(red: 32/255, green: 38/255, blue: 50/255)
        }
    }
    
    public var borderStroke: Color {
        accent.opacity(0.28)
    }
    
    public var glowColor: Color {
        accent.opacity(0.38)
    }
}
