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
    
    // MARK: - Built-in Structured Knowledge Base
    private struct TaxonomyRule {
        let phrase: String
        let category: String
        let subcategory: String?
        let productivity: ProductivityType
    }
    
    private static let builtInTaxonomy: [TaxonomyRule] = [
        // MARK: - Non-Productive: Groceries, Orders & Deliveries
        TaxonomyRule(phrase: "got big basket order", category: "Personal Errands", subcategory: "Groceries", productivity: .wasteful),
        TaxonomyRule(phrase: "big basket order", category: "Personal Errands", subcategory: "Groceries", productivity: .wasteful),
        TaxonomyRule(phrase: "big basket", category: "Personal Errands", subcategory: "Groceries", productivity: .wasteful),
        TaxonomyRule(phrase: "bigbasket order", category: "Personal Errands", subcategory: "Groceries", productivity: .wasteful),
        TaxonomyRule(phrase: "bigbasket", category: "Personal Errands", subcategory: "Groceries", productivity: .wasteful),
        TaxonomyRule(phrase: "blinkit order", category: "Personal Errands", subcategory: "Groceries", productivity: .wasteful),
        TaxonomyRule(phrase: "blinkit", category: "Personal Errands", subcategory: "Groceries", productivity: .wasteful),
        TaxonomyRule(phrase: "zepto order", category: "Personal Errands", subcategory: "Groceries", productivity: .wasteful),
        TaxonomyRule(phrase: "zepto", category: "Personal Errands", subcategory: "Groceries", productivity: .wasteful),
        TaxonomyRule(phrase: "instamart order", category: "Personal Errands", subcategory: "Groceries", productivity: .wasteful),
        TaxonomyRule(phrase: "instamart", category: "Personal Errands", subcategory: "Groceries", productivity: .wasteful),
        TaxonomyRule(phrase: "swiggy instamart", category: "Personal Errands", subcategory: "Groceries", productivity: .wasteful),
        TaxonomyRule(phrase: "grocery delivery", category: "Personal Errands", subcategory: "Groceries", productivity: .wasteful),
        TaxonomyRule(phrase: "grocery order", category: "Personal Errands", subcategory: "Groceries", productivity: .wasteful),
        TaxonomyRule(phrase: "grocery shopping", category: "Personal Errands", subcategory: "Groceries", productivity: .wasteful),
        TaxonomyRule(phrase: "groceries", category: "Personal Errands", subcategory: "Groceries", productivity: .wasteful),
        TaxonomyRule(phrase: "grocery", category: "Personal Errands", subcategory: "Groceries", productivity: .wasteful),
        TaxonomyRule(phrase: "amazon order", category: "Personal Errands", subcategory: "Shopping", productivity: .wasteful),
        TaxonomyRule(phrase: "flipkart order", category: "Personal Errands", subcategory: "Shopping", productivity: .wasteful),
        TaxonomyRule(phrase: "parcel delivery", category: "Personal Errands", subcategory: "Delivery", productivity: .wasteful),
        TaxonomyRule(phrase: "got parcel", category: "Personal Errands", subcategory: "Delivery", productivity: .wasteful),
        TaxonomyRule(phrase: "courier", category: "Personal Errands", subcategory: "Delivery", productivity: .wasteful),
        TaxonomyRule(phrase: "delivery", category: "Personal Errands", subcategory: "Delivery", productivity: .wasteful),
        TaxonomyRule(phrase: "shopping", category: "Personal Errands", subcategory: "Shopping", productivity: .wasteful),
        TaxonomyRule(phrase: "supermarket", category: "Personal Errands", subcategory: "Shopping", productivity: .wasteful),
        
        // MARK: - Non-Productive: Meals & Dining
        TaxonomyRule(phrase: "went to lunch", category: "Rest & Meals", subcategory: "Meals", productivity: .wasteful),
        TaxonomyRule(phrase: "went for lunch", category: "Rest & Meals", subcategory: "Meals", productivity: .wasteful),
        TaxonomyRule(phrase: "eating lunch", category: "Rest & Meals", subcategory: "Meals", productivity: .wasteful),
        TaxonomyRule(phrase: "had lunch", category: "Rest & Meals", subcategory: "Meals", productivity: .wasteful),
        TaxonomyRule(phrase: "having lunch", category: "Rest & Meals", subcategory: "Meals", productivity: .wasteful),
        TaxonomyRule(phrase: "at lunch", category: "Rest & Meals", subcategory: "Meals", productivity: .wasteful),
        TaxonomyRule(phrase: "lunch time", category: "Rest & Meals", subcategory: "Meals", productivity: .wasteful),
        TaxonomyRule(phrase: "lunch break", category: "Rest & Meals", subcategory: "Meals", productivity: .wasteful),
        TaxonomyRule(phrase: "lunch", category: "Rest & Meals", subcategory: "Meals", productivity: .wasteful),
        TaxonomyRule(phrase: "went to dinner", category: "Rest & Meals", subcategory: "Meals", productivity: .wasteful),
        TaxonomyRule(phrase: "went for dinner", category: "Rest & Meals", subcategory: "Meals", productivity: .wasteful),
        TaxonomyRule(phrase: "eating dinner", category: "Rest & Meals", subcategory: "Meals", productivity: .wasteful),
        TaxonomyRule(phrase: "had dinner", category: "Rest & Meals", subcategory: "Meals", productivity: .wasteful),
        TaxonomyRule(phrase: "having dinner", category: "Rest & Meals", subcategory: "Meals", productivity: .wasteful),
        TaxonomyRule(phrase: "dinner time", category: "Rest & Meals", subcategory: "Meals", productivity: .wasteful),
        TaxonomyRule(phrase: "dinner", category: "Rest & Meals", subcategory: "Meals", productivity: .wasteful),
        TaxonomyRule(phrase: "eating breakfast", category: "Rest & Meals", subcategory: "Meals", productivity: .wasteful),
        TaxonomyRule(phrase: "had breakfast", category: "Rest & Meals", subcategory: "Meals", productivity: .wasteful),
        TaxonomyRule(phrase: "breakfast", category: "Rest & Meals", subcategory: "Meals", productivity: .wasteful),
        TaxonomyRule(phrase: "brunch", category: "Rest & Meals", subcategory: "Meals", productivity: .wasteful),
        TaxonomyRule(phrase: "swiggy food", category: "Rest & Meals", subcategory: "Food Order", productivity: .wasteful),
        TaxonomyRule(phrase: "swiggy", category: "Rest & Meals", subcategory: "Food Order", productivity: .wasteful),
        TaxonomyRule(phrase: "zomato food", category: "Rest & Meals", subcategory: "Food Order", productivity: .wasteful),
        TaxonomyRule(phrase: "zomato", category: "Rest & Meals", subcategory: "Food Order", productivity: .wasteful),
        TaxonomyRule(phrase: "eating food", category: "Rest & Meals", subcategory: "Meals", productivity: .wasteful),
        TaxonomyRule(phrase: "eating", category: "Rest & Meals", subcategory: "Meals", productivity: .wasteful),
        TaxonomyRule(phrase: "ate food", category: "Rest & Meals", subcategory: "Meals", productivity: .wasteful),
        TaxonomyRule(phrase: "ate", category: "Rest & Meals", subcategory: "Meals", productivity: .wasteful),
        TaxonomyRule(phrase: "coffee break", category: "Rest & Meals", subcategory: "Break", productivity: .wasteful),
        TaxonomyRule(phrase: "tea break", category: "Rest & Meals", subcategory: "Break", productivity: .wasteful),
        TaxonomyRule(phrase: "chai break", category: "Rest & Meals", subcategory: "Break", productivity: .wasteful),
        TaxonomyRule(phrase: "chai", category: "Rest & Meals", subcategory: "Break", productivity: .wasteful),
        TaxonomyRule(phrase: "snacks", category: "Rest & Meals", subcategory: "Break", productivity: .wasteful),
        TaxonomyRule(phrase: "snack", category: "Rest & Meals", subcategory: "Break", productivity: .wasteful),
        TaxonomyRule(phrase: "canteen", category: "Rest & Meals", subcategory: "Meals", productivity: .wasteful),
        TaxonomyRule(phrase: "cafeteria", category: "Rest & Meals", subcategory: "Meals", productivity: .wasteful),
        TaxonomyRule(phrase: "restaurant", category: "Rest & Meals", subcategory: "Meals", productivity: .wasteful),
        
        // MARK: - Non-Productive: Personal Errands, Rest & Chores
        TaxonomyRule(phrase: "gym", category: "Personal Errands", subcategory: "Workout", productivity: .wasteful),
        TaxonomyRule(phrase: "workout", category: "Personal Errands", subcategory: "Workout", productivity: .wasteful),
        TaxonomyRule(phrase: "walk", category: "Rest & Meals", subcategory: "Walk", productivity: .wasteful),
        TaxonomyRule(phrase: "nap", category: "Rest & Meals", subcategory: "Rest", productivity: .wasteful),
        TaxonomyRule(phrase: "slept", category: "Rest & Meals", subcategory: "Rest", productivity: .wasteful),
        TaxonomyRule(phrase: "sleep", category: "Rest & Meals", subcategory: "Rest", productivity: .wasteful),
        TaxonomyRule(phrase: "break", category: "Rest & Meals", subcategory: "Break", productivity: .wasteful),
        TaxonomyRule(phrase: "commute", category: "Personal Errands", subcategory: "Travel", productivity: .wasteful),
        TaxonomyRule(phrase: "driving", category: "Personal Errands", subcategory: "Travel", productivity: .wasteful),
        TaxonomyRule(phrase: "traffic", category: "Personal Errands", subcategory: "Travel", productivity: .wasteful),
        TaxonomyRule(phrase: "chores", category: "Personal Errands", subcategory: "Chores", productivity: .wasteful),
        TaxonomyRule(phrase: "cleaning", category: "Personal Errands", subcategory: "Chores", productivity: .wasteful),
        TaxonomyRule(phrase: "laundry", category: "Personal Errands", subcategory: "Chores", productivity: .wasteful),
        TaxonomyRule(phrase: "errands", category: "Personal Errands", subcategory: "Errands", productivity: .wasteful),
        TaxonomyRule(phrase: "barber", category: "Personal Errands", subcategory: "Personal Care", productivity: .wasteful),
        TaxonomyRule(phrase: "salon", category: "Personal Errands", subcategory: "Personal Care", productivity: .wasteful),
        TaxonomyRule(phrase: "doctor", category: "Personal Errands", subcategory: "Health", productivity: .wasteful),
        TaxonomyRule(phrase: "hospital", category: "Personal Errands", subcategory: "Health", productivity: .wasteful),
        
        // MARK: - Non-Productive: Entertainment & Social Media
        TaxonomyRule(phrase: "youtube shorts", category: "YouTube Watching", subcategory: "Shorts", productivity: .wasteful),
        TaxonomyRule(phrase: "youtube", category: "YouTube Watching", subcategory: "Long Form", productivity: .wasteful),
        TaxonomyRule(phrase: "vlog", category: "YouTube Watching", subcategory: "Vlogs", productivity: .wasteful),
        TaxonomyRule(phrase: "reels", category: "Social Scrolling", subcategory: "Reels", productivity: .wasteful),
        TaxonomyRule(phrase: "instagram", category: "Social Scrolling", subcategory: "Instagram", productivity: .wasteful),
        TaxonomyRule(phrase: "insta", category: "Social Scrolling", subcategory: "Instagram", productivity: .wasteful),
        TaxonomyRule(phrase: "tiktok", category: "Social Scrolling", subcategory: "TikTok", productivity: .wasteful),
        TaxonomyRule(phrase: "twitter", category: "Social Scrolling", subcategory: "Twitter/X", productivity: .wasteful),
        TaxonomyRule(phrase: "x.com", category: "Social Scrolling", subcategory: "Twitter/X", productivity: .wasteful),
        TaxonomyRule(phrase: "reddit", category: "Social Scrolling", subcategory: "Reddit", productivity: .wasteful),
        TaxonomyRule(phrase: "room scrolling", category: "Social Scrolling", subcategory: "Feed", productivity: .wasteful),
        TaxonomyRule(phrase: "scrolling", category: "Social Scrolling", subcategory: "Feed", productivity: .wasteful),
        TaxonomyRule(phrase: "netflix", category: "Binge Watching", subcategory: "TV Shows", productivity: .wasteful),
        TaxonomyRule(phrase: "series", category: "Binge Watching", subcategory: "TV Shows", productivity: .wasteful),
        TaxonomyRule(phrase: "episode", category: "Binge Watching", subcategory: "TV Shows", productivity: .wasteful),
        TaxonomyRule(phrase: "anime", category: "Binge Watching", subcategory: "Anime", productivity: .wasteful),
        TaxonomyRule(phrase: "movie", category: "Movie Watching", subcategory: "Movies", productivity: .wasteful),
        TaxonomyRule(phrase: "film", category: "Movie Watching", subcategory: "Movies", productivity: .wasteful),
        TaxonomyRule(phrase: "cinema", category: "Movie Watching", subcategory: "Movies", productivity: .wasteful),
        TaxonomyRule(phrase: "valorant", category: "Gaming", subcategory: "Valorant", productivity: .wasteful),
        TaxonomyRule(phrase: "playing games", category: "Gaming", subcategory: "Gaming", productivity: .wasteful),
        TaxonomyRule(phrase: "playing cod", category: "Gaming", subcategory: "Call of Duty", productivity: .wasteful),
        TaxonomyRule(phrase: "cod", category: "Gaming", subcategory: "Call of Duty", productivity: .wasteful),
        TaxonomyRule(phrase: "gaming", category: "Gaming", subcategory: "Casual Games", productivity: .wasteful),
        TaxonomyRule(phrase: "game", category: "Gaming", subcategory: "Casual Games", productivity: .wasteful),
        TaxonomyRule(phrase: "fifa", category: "Gaming", subcategory: "Sports", productivity: .wasteful),
        TaxonomyRule(phrase: "pubg", category: "Gaming", subcategory: "Mobile", productivity: .wasteful),
        TaxonomyRule(phrase: "bgmi", category: "Gaming", subcategory: "Mobile", productivity: .wasteful),
        
        // MARK: - Non-Productive: Idle, Colloquial & Wasteful Activities
        TaxonomyRule(phrase: "doing nothing", category: "Rest & Leisure", subcategory: "Idle", productivity: .wasteful),
        TaxonomyRule(phrase: "did nothing", category: "Rest & Leisure", subcategory: "Idle", productivity: .wasteful),
        TaxonomyRule(phrase: "absolutely nothing", category: "Rest & Leisure", subcategory: "Idle", productivity: .wasteful),
        TaxonomyRule(phrase: "nothing", category: "Rest & Leisure", subcategory: "Idle", productivity: .wasteful),
        TaxonomyRule(phrase: "not much", category: "Rest & Leisure", subcategory: "Idle", productivity: .wasteful),
        TaxonomyRule(phrase: "chutiyap", category: "Rest & Leisure", subcategory: "Idle", productivity: .wasteful),
        TaxonomyRule(phrase: "chutiyapa", category: "Rest & Leisure", subcategory: "Idle", productivity: .wasteful),
        TaxonomyRule(phrase: "bakchodi", category: "Rest & Leisure", subcategory: "Idle", productivity: .wasteful),
        TaxonomyRule(phrase: "time pass", category: "Rest & Leisure", subcategory: "Idle", productivity: .wasteful),
        TaxonomyRule(phrase: "timepass", category: "Rest & Leisure", subcategory: "Idle", productivity: .wasteful),
        TaxonomyRule(phrase: "chilling", category: "Rest & Leisure", subcategory: "Relaxation", productivity: .wasteful),
        TaxonomyRule(phrase: "chill", category: "Rest & Leisure", subcategory: "Relaxation", productivity: .wasteful),
        TaxonomyRule(phrase: "idle", category: "Rest & Leisure", subcategory: "Idle", productivity: .wasteful),
        TaxonomyRule(phrase: "wasted", category: "Rest & Leisure", subcategory: "Idle", productivity: .wasteful),
        TaxonomyRule(phrase: "wasting time", category: "Rest & Leisure", subcategory: "Idle", productivity: .wasteful),
        TaxonomyRule(phrase: "procrastinating", category: "Rest & Leisure", subcategory: "Idle", productivity: .wasteful),
        TaxonomyRule(phrase: "procrastination", category: "Rest & Leisure", subcategory: "Idle", productivity: .wasteful),
        TaxonomyRule(phrase: "slacking", category: "Rest & Leisure", subcategory: "Idle", productivity: .wasteful),
        TaxonomyRule(phrase: "bored", category: "Rest & Leisure", subcategory: "Idle", productivity: .wasteful),
        TaxonomyRule(phrase: "faltu", category: "Rest & Leisure", subcategory: "Idle", productivity: .wasteful),
        TaxonomyRule(phrase: "nonsense", category: "Rest & Leisure", subcategory: "Idle", productivity: .wasteful),
        
        // MARK: - Productive: Coding & Software Engineering
        TaxonomyRule(phrase: "pair programming", category: "Deep Work", subcategory: "Coding", productivity: .productive),
        TaxonomyRule(phrase: "swiftui", category: "Deep Work", subcategory: "Coding", productivity: .productive),
        TaxonomyRule(phrase: "swift", category: "Deep Work", subcategory: "Coding", productivity: .productive),
        TaxonomyRule(phrase: "xcode", category: "Deep Work", subcategory: "Coding", productivity: .productive),
        TaxonomyRule(phrase: "coding", category: "Deep Work", subcategory: "Coding", productivity: .productive),
        TaxonomyRule(phrase: "programming", category: "Deep Work", subcategory: "Coding", productivity: .productive),
        TaxonomyRule(phrase: "bug fix", category: "Deep Work", subcategory: "Debugging", productivity: .productive),
        TaxonomyRule(phrase: "bugfix", category: "Deep Work", subcategory: "Debugging", productivity: .productive),
        TaxonomyRule(phrase: "debugging", category: "Deep Work", subcategory: "Debugging", productivity: .productive),
        TaxonomyRule(phrase: "debug", category: "Deep Work", subcategory: "Debugging", productivity: .productive),
        TaxonomyRule(phrase: "refactoring", category: "Deep Work", subcategory: "Refactoring", productivity: .productive),
        TaxonomyRule(phrase: "refactor", category: "Deep Work", subcategory: "Refactoring", productivity: .productive),
        TaxonomyRule(phrase: "architecture", category: "Deep Work", subcategory: "System Design", productivity: .productive),
        TaxonomyRule(phrase: "system design", category: "Deep Work", subcategory: "System Design", productivity: .productive),
        TaxonomyRule(phrase: "github", category: "Engineering", subcategory: "Version Control", productivity: .productive),
        TaxonomyRule(phrase: "pr review", category: "Engineering", subcategory: "Code Review", productivity: .productive),
        TaxonomyRule(phrase: "pull request", category: "Engineering", subcategory: "Code Review", productivity: .productive),
        TaxonomyRule(phrase: "terminal", category: "Engineering", subcategory: "DevOps", productivity: .productive),
        TaxonomyRule(phrase: "docker", category: "Engineering", subcategory: "DevOps", productivity: .productive),
        TaxonomyRule(phrase: "database", category: "Engineering", subcategory: "Backend", productivity: .productive),
        TaxonomyRule(phrase: "sqlite", category: "Engineering", subcategory: "Backend", productivity: .productive),
        TaxonomyRule(phrase: "backend", category: "Engineering", subcategory: "Backend", productivity: .productive),
        TaxonomyRule(phrase: "frontend", category: "Engineering", subcategory: "Frontend", productivity: .productive),
        TaxonomyRule(phrase: "api", category: "Engineering", subcategory: "Backend", productivity: .productive),
        TaxonomyRule(phrase: "python", category: "Deep Work", subcategory: "Coding", productivity: .productive),
        TaxonomyRule(phrase: "typescript", category: "Deep Work", subcategory: "Coding", productivity: .productive),
        TaxonomyRule(phrase: "javascript", category: "Deep Work", subcategory: "Coding", productivity: .productive),
        TaxonomyRule(phrase: "react", category: "Deep Work", subcategory: "Coding", productivity: .productive),
        
        // MARK: - Productive: Design, UI/UX & Creative
        TaxonomyRule(phrase: "ui review", category: "Deep Work", subcategory: "UI/UX", productivity: .productive),
        TaxonomyRule(phrase: "design system", category: "Deep Work", subcategory: "UI/UX", productivity: .productive),
        TaxonomyRule(phrase: "figma", category: "Deep Work", subcategory: "UI/UX", productivity: .productive),
        TaxonomyRule(phrase: "design", category: "Deep Work", subcategory: "UI/UX", productivity: .productive),
        TaxonomyRule(phrase: "wireframe", category: "Deep Work", subcategory: "UI/UX", productivity: .productive),
        TaxonomyRule(phrase: "prototype", category: "Deep Work", subcategory: "UI/UX", productivity: .productive),
        
        // MARK: - Productive: Collaboration, Meetings & Planning
        TaxonomyRule(phrase: "client call", category: "Meetings", subcategory: "Client", productivity: .productive),
        TaxonomyRule(phrase: "standup", category: "Meetings", subcategory: "Standup", productivity: .productive),
        TaxonomyRule(phrase: "team meeting", category: "Meetings", subcategory: "Team Call", productivity: .productive),
        TaxonomyRule(phrase: "meeting", category: "Meetings", subcategory: "Team Call", productivity: .productive),
        TaxonomyRule(phrase: "1:1", category: "Meetings", subcategory: "1:1", productivity: .productive),
        TaxonomyRule(phrase: "sync", category: "Meetings", subcategory: "Sync", productivity: .productive),
        TaxonomyRule(phrase: "planning", category: "Planning", subcategory: "Roadmap", productivity: .productive),
        TaxonomyRule(phrase: "roadmap", category: "Planning", subcategory: "Roadmap", productivity: .productive),
        TaxonomyRule(phrase: "sprint", category: "Planning", subcategory: "Agile", productivity: .productive),
        TaxonomyRule(phrase: "presentation", category: "Deep Work", subcategory: "Slides", productivity: .productive),
        TaxonomyRule(phrase: "deck", category: "Deep Work", subcategory: "Slides", productivity: .productive),
        TaxonomyRule(phrase: "email", category: "Admin", subcategory: "Email", productivity: .productive),
        TaxonomyRule(phrase: "slack", category: "Admin", subcategory: "Communication", productivity: .productive),
        
        // MARK: - Productive: Learning & Research
        TaxonomyRule(phrase: "reading docs", category: "Learning", subcategory: "Docs", productivity: .productive),
        TaxonomyRule(phrase: "studying", category: "Learning", subcategory: "Study", productivity: .productive),
        TaxonomyRule(phrase: "study", category: "Learning", subcategory: "Study", productivity: .productive),
        TaxonomyRule(phrase: "research", category: "Learning", subcategory: "Research", productivity: .productive),
        TaxonomyRule(phrase: "homework", category: "Learning", subcategory: "Study", productivity: .productive),
        TaxonomyRule(phrase: "assignment", category: "Learning", subcategory: "Study", productivity: .productive),
        TaxonomyRule(phrase: "lecture", category: "Learning", subcategory: "Study", productivity: .productive)
    ]
    
    // MARK: - Classification
    public static func classify(text: String, rules: [ClassificationRule]) -> ClassificationMatch? {
        let lowerText = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if lowerText.isEmpty { return nil }
        
        // 1. Check user-defined rules from database (sorted by longest phrase first)
        let sortedUserRules = rules.sorted { $0.phrase.count > $1.phrase.count }
        for rule in sortedUserRules {
            let phrase = rule.phrase.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            if !phrase.isEmpty && (lowerText.contains(phrase) || matchesWordToken(text: lowerText, phrase: phrase)) {
                return ClassificationMatch(
                    category: rule.category,
                    subcategory: rule.subcategory,
                    productivity: rule.productivityType,
                    matchedPhrase: rule.phrase
                )
            }
        }
        
        // 2. Check built-in structured taxonomy (longest phrase first)
        let sortedTaxonomy = builtInTaxonomy.sorted { $0.phrase.count > $1.phrase.count }
        for item in sortedTaxonomy {
            if lowerText.contains(item.phrase) || matchesWordToken(text: lowerText, phrase: item.phrase) {
                return ClassificationMatch(
                    category: item.category,
                    subcategory: item.subcategory,
                    productivity: item.productivity,
                    matchedPhrase: item.phrase
                )
            }
        }
        
        // 3. Heuristic / Semantic Keyword Fallback (strictly binary: Productive vs Non-Productive)
        let nonProductiveKeywords = [
            "nothing", "chutiyap", "chutiyapa", "bakchodi", "timepass", "chill", "chilling", "idle", "wasted",
            "bored", "nonsense", "faltu", "slacking", "lounging",
            "order", "delivery", "delivered", "grocery", "groceries", "bought", "buy", "purchase", "shopping",
            "lunch", "dinner", "breakfast", "brunch", "eat", "eating", "food", "snack", "coffee", "tea",
            "walk", "nap", "sleep", "slept", "break", "gym", "workout", "errand", "errands", "drive", "driving",
            "game", "gaming", "play", "playing", "watch", "watching", "reels", "shorts", "scroll", "scrolling",
            "clean", "cleaning", "wash", "laundry", "cook", "cooking"
        ]
        
        for kw in nonProductiveKeywords {
            if lowerText.contains(kw) || matchesWordToken(text: lowerText, phrase: kw) {
                let category: String
                if ["nothing", "chutiyap", "chutiyapa", "bakchodi", "timepass", "chill", "chilling", "idle", "wasted", "bored", "nonsense", "faltu", "slacking", "lounging"].contains(kw) {
                    category = "Rest & Leisure"
                } else if ["order", "delivery", "delivered", "grocery", "groceries", "bought", "buy", "shopping"].contains(kw) {
                    category = "Personal Errands"
                } else if ["lunch", "dinner", "breakfast", "brunch", "eat", "eating", "food", "snack", "coffee", "tea"].contains(kw) {
                    category = "Rest & Meals"
                } else {
                    category = "Break"
                }
                
                return ClassificationMatch(
                    category: category,
                    subcategory: nil,
                    productivity: .wasteful,
                    matchedPhrase: kw
                )
            }
        }
        
        // If technical/work terms exist
        let productiveKeywords = [
            "code", "build", "debug", "fix", "write", "draft", "read", "review", "test", "deploy",
            "plan", "meet", "call", "discuss", "study", "learn", "solve", "work", "implement", "analyze"
        ]
        
        for kw in productiveKeywords {
            if matchesWordToken(text: lowerText, phrase: kw) {
                return ClassificationMatch(
                    category: "Deep Work",
                    subcategory: nil,
                    productivity: .productive,
                    matchedPhrase: kw
                )
            }
        }
        
        // Default fallback: If unrecognized, default to Non-Productive (Personal) rather than falsely marking as Productive
        return ClassificationMatch(
            category: "Personal / Uncategorized",
            subcategory: nil,
            productivity: .wasteful,
            matchedPhrase: text
        )
    }
    
    private static func matchesWordToken(text: String, phrase: String) -> Bool {
        let pattern = "\\b\(NSRegularExpression.escapedPattern(for: phrase))\\b"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return text.contains(phrase)
        }
        let range = NSRange(location: 0, length: text.utf16.count)
        return regex.firstMatch(in: text, options: [], range: range) != nil
    }
    
    public static func learnRule(for rawText: String, category: String, subcategory: String? = nil, productivity: ProductivityType, db: DatabaseManager = .shared) {
        let trimmed = rawText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return }
        
        let rule = ClassificationRule(
            phrase: trimmed,
            category: category,
            subcategory: subcategory,
            productivity: productivity.rawValue
        )
        db.insertRule(rule)
    }
}
