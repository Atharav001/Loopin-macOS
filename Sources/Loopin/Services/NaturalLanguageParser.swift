import Foundation

// MARK: - ParsedTimeResult
public struct ParsedTaskResult: Equatable, Sendable {
    public var title: String
    public var startAt: Date
    public var endAt: Date
    
    public init(title: String, startAt: Date, endAt: Date) {
        self.title = title
        self.startAt = startAt
        self.endAt = endAt
    }
}

// MARK: - NaturalLanguageParser
public struct NaturalLanguageParser: Sendable {
    public static func parse(text: String, baseDate: Date = Date()) -> ParsedTaskResult {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            let start = baseDate
            let end = Calendar.current.date(byAdding: .hour, value: 1, to: start) ?? start.addingTimeInterval(3600)
            return ParsedTaskResult(title: "New Task", startAt: start, endAt: end)
        }
        
        let cal = Calendar.current
        let startOfDay = cal.startOfDay(for: baseDate)
        
        // Regex for patterns like "coding 2-4pm", "meeting 10am to 11am", "design 14:00-16:00", "lunch 12:30-1:30pm"
        // Pattern 1: (\d{1,2}(?::\d{2})?\s*(?:am|pm)?)\s*(?:-|to)\s*(\d{1,2}(?::\d{2})?\s*(?:am|pm)?)
        let timeRangeRegex = try? NSRegularExpression(
            pattern: #"\b(\d{1,2}(?::\d{2})?\s*(?:am|pm)?)\s*(?:-|to)\s*(\d{1,2}(?::\d{2})?\s*(?:am|pm)?)\b"#,
            options: .caseInsensitive
        )
        
        if let match = timeRangeRegex?.firstMatch(in: trimmed, options: [], range: NSRange(location: 0, length: trimmed.utf16.count)) {
            let fullRange = match.range
            let startStr = (trimmed as NSString).substring(with: match.range(at: 1))
            let endStr = (trimmed as NSString).substring(with: match.range(at: 2))
            
            var taskTitle = (trimmed as NSString).replacingCharacters(in: fullRange, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            if taskTitle.isEmpty {
                taskTitle = "Planned Task"
            }
            
            // Determine if am/pm is specified on endStr and implied on startStr (e.g. "2-4pm")
            let isEndPM = endStr.lowercased().contains("pm")
            let isEndAM = endStr.lowercased().contains("am")
            let startHasMeridiem = startStr.lowercased().contains("am") || startStr.lowercased().contains("pm")
            
            let (startHour, startMin) = parseTimeComponents(str: startStr, inheritPM: !startHasMeridiem && isEndPM, inheritAM: !startHasMeridiem && isEndAM)
            let (endHour, endMin) = parseTimeComponents(str: endStr, inheritPM: false, inheritAM: false)
            
            var startDate = cal.date(bySettingHour: startHour, minute: startMin, second: 0, of: startOfDay) ?? baseDate
            var endDate = cal.date(bySettingHour: endHour, minute: endMin, second: 0, of: startOfDay) ?? baseDate.addingTimeInterval(3600)
            
            if endDate <= startDate {
                // If end is less than start, it might wrap into next day or be 12-hour ambiguity
                if endHour < startHour && endHour < 12 {
                    endDate = cal.date(bySettingHour: endHour + 12, minute: endMin, second: 0, of: startOfDay) ?? endDate
                }
                if endDate <= startDate {
                    endDate = cal.date(byAdding: .hour, value: 1, to: startDate) ?? startDate.addingTimeInterval(3600)
                }
            }
            
            return ParsedTaskResult(title: taskTitle, startAt: startDate, endAt: endDate)
        }
        
        // Single time pattern: "meeting at 3pm", "call 11:30am"
        let singleTimeRegex = try? NSRegularExpression(
            pattern: #"\b(?:at\s+)?(\d{1,2}(?::\d{2})?\s*(?:am|pm))\b"#,
            options: .caseInsensitive
        )
        
        if let match = singleTimeRegex?.firstMatch(in: trimmed, options: [], range: NSRange(location: 0, length: trimmed.utf16.count)) {
            let fullRange = match.range
            let timeStr = (trimmed as NSString).substring(with: match.range(at: 1))
            var taskTitle = (trimmed as NSString).replacingCharacters(in: fullRange, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            if taskTitle.isEmpty { taskTitle = "Planned Task" }
            
            let (hour, min) = parseTimeComponents(str: timeStr, inheritPM: false, inheritAM: false)
            let startDate = cal.date(bySettingHour: hour, minute: min, second: 0, of: startOfDay) ?? baseDate
            let endDate = cal.date(byAdding: .hour, value: 1, to: startDate) ?? startDate.addingTimeInterval(3600)
            
            return ParsedTaskResult(title: taskTitle, startAt: startDate, endAt: endDate)
        }
        
        // Default: use current time rounded to 15m and 1 hour duration
        let currentMinutes = cal.component(.minute, from: baseDate)
        let roundedMinutes = Int(round(Double(currentMinutes) / 15.0) * 15.0)
        let hour = cal.component(.hour, from: baseDate)
        
        let start = cal.date(bySettingHour: hour, minute: 0, second: 0, of: startOfDay)?.addingTimeInterval(Double(roundedMinutes * 60)) ?? baseDate
        let end = cal.date(byAdding: .hour, value: 1, to: start) ?? start.addingTimeInterval(3600)
        
        return ParsedTaskResult(title: trimmed, startAt: start, endAt: end)
    }
    
    private static func parseTimeComponents(str: String, inheritPM: Bool, inheritAM: Bool) -> (hour: Int, minute: Int) {
        let clean = str.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let isPM = clean.contains("pm") || inheritPM
        let isAM = clean.contains("am") || inheritAM
        
        let digitsOnly = clean.replacingOccurrences(of: "am", with: "").replacingOccurrences(of: "pm", with: "").trimmingCharacters(in: .whitespaces)
        let parts = digitsOnly.split(separator: ":")
        
        var hour = Int(parts.first ?? "0") ?? 0
        var minute = 0
        if parts.count > 1 {
            minute = Int(parts[1]) ?? 0
        }
        
        if isPM && hour < 12 {
            hour += 12
        } else if isAM && hour == 12 {
            hour = 0
        }
        
        hour = max(0, min(23, hour))
        minute = max(0, min(59, minute))
        
        return (hour, minute)
    }
}
