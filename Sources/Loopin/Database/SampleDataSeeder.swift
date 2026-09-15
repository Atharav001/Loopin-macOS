import Foundation

// MARK: - SampleDataSeeder
public struct SampleDataSeeder {
    public static func seedDefaultRulesIfNeeded(db: DatabaseManager = .shared) {
        let existingRules = db.fetchAllRules()
        if existingRules.isEmpty {
            let defaultRules: [ClassificationRule] = [
                ClassificationRule(phrase: "coding", category: "Coding", productivity: "productive"),
                ClassificationRule(phrase: "swift", category: "Coding", productivity: "productive"),
                ClassificationRule(phrase: "xcode", category: "Coding", productivity: "productive"),
                ClassificationRule(phrase: "bug fix", category: "Coding", productivity: "productive"),
                ClassificationRule(phrase: "github", category: "Engineering", productivity: "productive"),
                ClassificationRule(phrase: "pr review", category: "Engineering", productivity: "productive"),
                ClassificationRule(phrase: "design", category: "Design", productivity: "productive"),
                ClassificationRule(phrase: "figma", category: "Design", productivity: "productive"),
                ClassificationRule(phrase: "ui review", category: "Design", productivity: "productive"),
                ClassificationRule(phrase: "meeting", category: "Meeting", productivity: "neutral"),
                ClassificationRule(phrase: "standup", category: "Meeting", productivity: "neutral"),
                ClassificationRule(phrase: "sync", category: "Meeting", productivity: "neutral"),
                ClassificationRule(phrase: "research", category: "Research", productivity: "productive"),
                ClassificationRule(phrase: "reading docs", category: "Research", productivity: "productive"),
                ClassificationRule(phrase: "email", category: "Email & Admin", productivity: "neutral"),
                ClassificationRule(phrase: "planning", category: "Planning", productivity: "productive"),
                ClassificationRule(phrase: "lunch", category: "Break", productivity: "neutral"),
                ClassificationRule(phrase: "coffee", category: "Break", productivity: "neutral"),
                ClassificationRule(phrase: "youtube shorts", category: "YouTube Watching", productivity: "wasteful"),
                ClassificationRule(phrase: "youtube", category: "YouTube Watching", productivity: "wasteful"),
                ClassificationRule(phrase: "twitter", category: "Social Media", productivity: "wasteful"),
                ClassificationRule(phrase: "x.com", category: "Social Media", productivity: "wasteful"),
                ClassificationRule(phrase: "reddit", category: "Social Media", productivity: "wasteful"),
                ClassificationRule(phrase: "gaming", category: "Gaming", productivity: "wasteful")
            ]
            
            for rule in defaultRules {
                db.insertRule(rule)
            }
        }
    }
    
    public static func seedSampleEntries(db: DatabaseManager = .shared) {
        let cal = Calendar.current
        let today = Date()
        let startOfToday = cal.startOfDay(for: today)
        
        // Sample entries for today
        let entries: [TimesheetEntry] = [
            TimesheetEntry(
                kind: EntryKind.planned.rawValue,
                startAt: cal.date(byAdding: .hour, value: 9, to: startOfToday)!,
                endAt: cal.date(byAdding: .hour, value: 11, to: startOfToday)!,
                rawText: "Core AppKit window architecture",
                inputMethod: InputMethod.typed.rawValue,
                category: "Coding",
                productivity: ProductivityType.productive.rawValue
            ),
            TimesheetEntry(
                kind: EntryKind.logged.rawValue,
                startAt: cal.date(byAdding: .hour, value: 9, to: startOfToday)!,
                endAt: cal.date(byAdding: .minute, value: 115, to: cal.date(byAdding: .hour, value: 9, to: startOfToday)!)!,
                rawText: "Building AppKit NSWindow shell",
                inputMethod: InputMethod.typed.rawValue,
                category: "Coding",
                productivity: ProductivityType.productive.rawValue
            ),
            TimesheetEntry(
                kind: EntryKind.logged.rawValue,
                startAt: cal.date(byAdding: .hour, value: 11, to: startOfToday)!,
                endAt: cal.date(byAdding: .minute, value: 30, to: cal.date(byAdding: .hour, value: 11, to: startOfToday)!)!,
                rawText: "Team sync meeting",
                inputMethod: InputMethod.typed.rawValue,
                category: "Meeting",
                productivity: ProductivityType.neutral.rawValue
            ),
            TimesheetEntry(
                kind: EntryKind.logged.rawValue,
                startAt: cal.date(byAdding: .minute, value: 45, to: cal.date(byAdding: .hour, value: 11, to: startOfToday)!)!,
                endAt: cal.date(byAdding: .minute, value: 75, to: cal.date(byAdding: .hour, value: 11, to: startOfToday)!)!,
                rawText: "Checked Twitter feed",
                inputMethod: InputMethod.typed.rawValue,
                category: "Social Media",
                productivity: ProductivityType.wasteful.rawValue
            ),
            TimesheetEntry(
                kind: EntryKind.planned.rawValue,
                startAt: cal.date(byAdding: .hour, value: 14, to: startOfToday)!,
                endAt: cal.date(byAdding: .hour, value: 17, to: startOfToday)!,
                rawText: "Interactive Week Calendar Grid & Drag",
                inputMethod: InputMethod.typed.rawValue,
                category: "Coding",
                productivity: ProductivityType.productive.rawValue
            )
        ]
        
        for entry in entries {
            db.insertEntry(entry)
        }
    }
}
