import Foundation

// MARK: - SampleDataSeeder
public struct SampleDataSeeder {
    public static func seedDefaultRulesIfNeeded(db: DatabaseManager = .shared) {
        let existingRules = db.fetchAllRules()
        if existingRules.isEmpty {
            let defaultRules: [ClassificationRule] = [
                // Productive - Deep Work & Engineering
                ClassificationRule(phrase: "coding", category: "Deep Work", subcategory: "Coding", productivity: "productive"),
                ClassificationRule(phrase: "swift", category: "Deep Work", subcategory: "Coding", productivity: "productive"),
                ClassificationRule(phrase: "xcode", category: "Deep Work", subcategory: "Coding", productivity: "productive"),
                ClassificationRule(phrase: "bug fix", category: "Deep Work", subcategory: "Debugging", productivity: "productive"),
                ClassificationRule(phrase: "debugging", category: "Deep Work", subcategory: "Debugging", productivity: "productive"),
                ClassificationRule(phrase: "architecture", category: "Deep Work", subcategory: "System Design", productivity: "productive"),
                ClassificationRule(phrase: "github", category: "Engineering", subcategory: "Version Control", productivity: "productive"),
                ClassificationRule(phrase: "pr review", category: "Engineering", subcategory: "Code Review", productivity: "productive"),
                ClassificationRule(phrase: "terminal", category: "Engineering", subcategory: "DevOps", productivity: "productive"),
                ClassificationRule(phrase: "docker", category: "Engineering", subcategory: "DevOps", productivity: "productive"),
                ClassificationRule(phrase: "design", category: "Deep Work", subcategory: "UI/UX", productivity: "productive"),
                ClassificationRule(phrase: "figma", category: "Deep Work", subcategory: "UI/UX", productivity: "productive"),
                ClassificationRule(phrase: "ui review", category: "Deep Work", subcategory: "UI/UX", productivity: "productive"),
                
                // Productive - Collaboration & Learning
                ClassificationRule(phrase: "meeting", category: "Meetings", subcategory: "Team Call", productivity: "productive"),
                ClassificationRule(phrase: "standup", category: "Meetings", subcategory: "Standup", productivity: "productive"),
                ClassificationRule(phrase: "sync", category: "Meetings", subcategory: "Sync", productivity: "productive"),
                ClassificationRule(phrase: "client call", category: "Meetings", subcategory: "Client", productivity: "productive"),
                ClassificationRule(phrase: "research", category: "Learning", subcategory: "Research", productivity: "productive"),
                ClassificationRule(phrase: "reading docs", category: "Learning", subcategory: "Docs", productivity: "productive"),
                ClassificationRule(phrase: "studying", category: "Learning", subcategory: "Study", productivity: "productive"),
                
                // Neutral - Admin & Rest
                ClassificationRule(phrase: "email", category: "Admin", subcategory: "Email", productivity: "neutral"),
                ClassificationRule(phrase: "slack", category: "Admin", subcategory: "Communication", productivity: "neutral"),
                ClassificationRule(phrase: "planning", category: "Admin", subcategory: "Planning", productivity: "neutral"),
                ClassificationRule(phrase: "lunch", category: "Rest", subcategory: "Meals", productivity: "neutral"),
                ClassificationRule(phrase: "dinner", category: "Rest", subcategory: "Meals", productivity: "neutral"),
                ClassificationRule(phrase: "coffee", category: "Rest", subcategory: "Break", productivity: "neutral"),
                ClassificationRule(phrase: "walk", category: "Rest", subcategory: "Exercise", productivity: "neutral"),
                ClassificationRule(phrase: "gym", category: "Rest", subcategory: "Exercise", productivity: "neutral"),
                ClassificationRule(phrase: "commute", category: "Rest", subcategory: "Travel", productivity: "neutral"),
                
                // Wasteful - Specific Hierarchy requested by user
                ClassificationRule(phrase: "re-watching room scrolling", category: "Social Scrolling", subcategory: "Room Scrolling", productivity: "wasteful"),
                ClassificationRule(phrase: "room scrolling", category: "Social Scrolling", subcategory: "Room Scrolling", productivity: "wasteful"),
                ClassificationRule(phrase: "scrolling", category: "Social Scrolling", subcategory: "Feed Scrolling", productivity: "wasteful"),
                ClassificationRule(phrase: "reels", category: "Social Scrolling", subcategory: "Reels", productivity: "wasteful"),
                ClassificationRule(phrase: "tiktok", category: "Social Scrolling", subcategory: "TikTok", productivity: "wasteful"),
                ClassificationRule(phrase: "instagram", category: "Social Scrolling", subcategory: "Instagram", productivity: "wasteful"),
                ClassificationRule(phrase: "insta", category: "Social Scrolling", subcategory: "Instagram", productivity: "wasteful"),
                ClassificationRule(phrase: "twitter", category: "Social Scrolling", subcategory: "Twitter/X", productivity: "wasteful"),
                ClassificationRule(phrase: "x.com", category: "Social Scrolling", subcategory: "Twitter/X", productivity: "wasteful"),
                ClassificationRule(phrase: "reddit", category: "Social Scrolling", subcategory: "Reddit", productivity: "wasteful"),
                
                ClassificationRule(phrase: "youtube shorts", category: "YouTube Watching", subcategory: "Shorts", productivity: "wasteful"),
                ClassificationRule(phrase: "youtube", category: "YouTube Watching", subcategory: "Long Form", productivity: "wasteful"),
                ClassificationRule(phrase: "vlog", category: "YouTube Watching", subcategory: "Vlogs", productivity: "wasteful"),
                
                ClassificationRule(phrase: "binge watching", category: "Binge Watching", subcategory: "TV Shows", productivity: "wasteful"),
                ClassificationRule(phrase: "netflix", category: "Binge Watching", subcategory: "TV Shows", productivity: "wasteful"),
                ClassificationRule(phrase: "series", category: "Binge Watching", subcategory: "TV Shows", productivity: "wasteful"),
                ClassificationRule(phrase: "episode", category: "Binge Watching", subcategory: "TV Shows", productivity: "wasteful"),
                ClassificationRule(phrase: "season", category: "Binge Watching", subcategory: "TV Shows", productivity: "wasteful"),
                ClassificationRule(phrase: "anime", category: "Binge Watching", subcategory: "Anime", productivity: "wasteful"),
                
                ClassificationRule(phrase: "movie binge watching", category: "Movie Watching", subcategory: "Marathon", productivity: "wasteful"),
                ClassificationRule(phrase: "movie", category: "Movie Watching", subcategory: "Movies", productivity: "wasteful"),
                ClassificationRule(phrase: "film", category: "Movie Watching", subcategory: "Movies", productivity: "wasteful"),
                ClassificationRule(phrase: "cinema", category: "Movie Watching", subcategory: "Movies", productivity: "wasteful"),
                
                ClassificationRule(phrase: "playing games", category: "Gaming", subcategory: "Gaming", productivity: "wasteful"),
                ClassificationRule(phrase: "playing cod", category: "Gaming", subcategory: "Call of Duty", productivity: "wasteful"),
                ClassificationRule(phrase: "cod", category: "Gaming", subcategory: "Call of Duty", productivity: "wasteful"),
                ClassificationRule(phrase: "valorant", category: "Gaming", subcategory: "Valorant", productivity: "wasteful"),
                ClassificationRule(phrase: "game", category: "Gaming", subcategory: "Casual Games", productivity: "wasteful"),
                ClassificationRule(phrase: "gaming", category: "Gaming", subcategory: "Casual Games", productivity: "wasteful")
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
        
        let entries: [TimesheetEntry] = [
            TimesheetEntry(
                kind: EntryKind.planned.rawValue,
                startAt: cal.date(byAdding: .hour, value: 9, to: startOfToday)!,
                endAt: cal.date(byAdding: .hour, value: 11, to: startOfToday)!,
                rawText: "Core AppKit window architecture",
                inputMethod: InputMethod.typed.rawValue,
                category: "Deep Work",
                subcategory: "System Design",
                productivity: ProductivityType.productive.rawValue
            ),
            TimesheetEntry(
                kind: EntryKind.logged.rawValue,
                startAt: cal.date(byAdding: .hour, value: 9, to: startOfToday)!,
                endAt: cal.date(byAdding: .minute, value: 115, to: cal.date(byAdding: .hour, value: 9, to: startOfToday)!)!,
                rawText: "Building AppKit NSWindow shell",
                inputMethod: InputMethod.typed.rawValue,
                category: "Deep Work",
                subcategory: "Coding",
                productivity: ProductivityType.productive.rawValue
            ),
            TimesheetEntry(
                kind: EntryKind.logged.rawValue,
                startAt: cal.date(byAdding: .hour, value: 11, to: startOfToday)!,
                endAt: cal.date(byAdding: .minute, value: 30, to: cal.date(byAdding: .hour, value: 11, to: startOfToday)!)!,
                rawText: "Team sync meeting",
                inputMethod: InputMethod.typed.rawValue,
                category: "Meetings",
                subcategory: "Standup",
                productivity: ProductivityType.productive.rawValue
            ),
            TimesheetEntry(
                kind: EntryKind.logged.rawValue,
                startAt: cal.date(byAdding: .minute, value: 45, to: cal.date(byAdding: .hour, value: 11, to: startOfToday)!)!,
                endAt: cal.date(byAdding: .minute, value: 75, to: cal.date(byAdding: .hour, value: 11, to: startOfToday)!)!,
                rawText: "Checked Twitter feed and room scrolling",
                inputMethod: InputMethod.typed.rawValue,
                category: "Social Scrolling",
                subcategory: "Room Scrolling",
                productivity: ProductivityType.wasteful.rawValue
            ),
            TimesheetEntry(
                kind: EntryKind.planned.rawValue,
                startAt: cal.date(byAdding: .hour, value: 14, to: startOfToday)!,
                endAt: cal.date(byAdding: .hour, value: 17, to: startOfToday)!,
                rawText: "Interactive Week Calendar Grid & Drag",
                inputMethod: InputMethod.typed.rawValue,
                category: "Deep Work",
                subcategory: "Coding",
                productivity: ProductivityType.productive.rawValue
            )
        ]
        
        for entry in entries {
            db.insertEntry(entry)
        }
    }
}
