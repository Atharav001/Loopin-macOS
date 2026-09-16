import Foundation

// MARK: - ProductivityType
public enum ProductivityType: String, Codable, CaseIterable, Sendable {
    case productive = "productive"
    case wasteful = "wasteful"
    case neutral = "neutral" // Legacy database mapping
    
    public static var allCases: [ProductivityType] {
        return [.productive, .wasteful]
    }
    
    public var displayName: String {
        switch self {
        case .productive: return "Productive"
        case .wasteful, .neutral: return "Non-Productive"
        }
    }
    
    public var isProductive: Bool {
        return self == .productive
    }
}

// MARK: - EntryKind
public enum EntryKind: String, Codable, CaseIterable, Sendable {
    case planned = "planned"
    case logged = "logged"
    
    public var displayName: String {
        switch self {
        case .planned: return "Planned"
        case .logged: return "Logged"
        }
    }
}

// MARK: - InputMethod
public enum InputMethod: String, Codable, CaseIterable, Sendable {
    case typed = "typed"
    case voice = "voice"
    case skipped = "skipped"
    
    public var displayName: String {
        switch self {
        case .typed: return "Typed"
        case .voice: return "Voice"
        case .skipped: return "Skipped"
        }
    }
}

// MARK: - TimesheetEntry
public struct TimesheetEntry: Identifiable, Codable, Equatable, Sendable {
    public var id: String
    public var kind: String          // "planned" | "logged"
    public var startAt: Date
    public var endAt: Date
    public var rawText: String
    public var inputMethod: String   // "typed" | "voice" | "skipped"
    public var category: String?
    public var subcategory: String?
    public var productivity: String? // "productive" | "neutral" | "wasteful"
    public var gcalEventId: String?
    public var deviceId: String
    public var isSynced: Bool
    public var updatedAt: Date
    
    public init(
        id: String = UUID().uuidString,
        kind: String = EntryKind.logged.rawValue,
        startAt: Date,
        endAt: Date,
        rawText: String,
        inputMethod: String = InputMethod.typed.rawValue,
        category: String? = nil,
        subcategory: String? = nil,
        productivity: String? = nil,
        gcalEventId: String? = nil,
        deviceId: String = "macOS",
        isSynced: Bool = false,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.kind = kind
        self.startAt = startAt
        self.endAt = endAt
        self.rawText = rawText
        self.inputMethod = inputMethod
        self.category = category
        self.subcategory = subcategory
        self.productivity = productivity
        self.gcalEventId = gcalEventId
        self.deviceId = deviceId
        self.isSynced = isSynced
        self.updatedAt = updatedAt
    }
    
    public var duration: TimeInterval {
        return max(0, endAt.timeIntervalSince(startAt))
    }
    
    public var durationMinutes: Int {
        return Int(round(duration / 60.0))
    }
    
    public var entryKind: EntryKind {
        return EntryKind(rawValue: kind) ?? .logged
    }
    
    public var productivityType: ProductivityType? {
        guard let prod = productivity else { return nil }
        return ProductivityType(rawValue: prod)
    }
    
    public var formattedDuration: String {
        let mins = durationMinutes
        if mins < 60 {
            return "\(mins)m"
        } else {
            let hrs = mins / 60
            let remainder = mins % 60
            if remainder == 0 {
                return "\(hrs)h"
            } else {
                return "\(hrs)h \(remainder)m"
            }
        }
    }
    
    public var formattedTimeRange: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: startAt)) – \(formatter.string(from: endAt))"
    }
}
