import SwiftUI

public struct WeekCalendarView: View {
    @ObservedObject var appState: AppState = .shared
    @State private var currentWeekStart: Date = {
        let cal = Calendar.current
        var comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        comps.weekday = 2 // Monday start
        return cal.date(from: comps) ?? Date()
    }()
    
    @State private var entries: [TimesheetEntry] = []
    @State private var selectedEntryForEdit: TimesheetEntry?
    @State private var isShowingEditor: Bool = false
    
    private let hourHeight: CGFloat = 48
    
    public init() {}
    
    private var weekDays: [Date] {
        let cal = Calendar.current
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: currentWeekStart) }
    }
    
    private var totalWeeklyDurationFormatted: String {
        let totalMins = entries.reduce(0) { $0 + $1.durationMinutes }
        let hrs = totalMins / 60
        let mins = totalMins % 60
        return "\(hrs)h \(mins)m"
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Week Header Bar
            headerBar
            
            // 7 Day Headers Row
            dayHeadersRow
            
            // 2D Scrollable Grid
            ScrollView([.horizontal, .vertical], showsIndicators: true) {
                HStack(alignment: .top, spacing: 0) {
                    // Time Gutter (00:00 - 23:00)
                    TimeGutterView(hourHeight: hourHeight)
                    
                    // 7 Day Columns
                    HStack(spacing: 0) {
                        ForEach(weekDays, id: \.self) { day in
                            let dayEntries = entriesForDay(day)
                            let isToday = Calendar.current.isDateInToday(day)
                            
                            DayColumnView(
                                date: day,
                                entries: dayEntries,
                                hourHeight: hourHeight,
                                isToday: isToday,
                                onSelectEntry: { entry in
                                    selectedEntryForEdit = entry
                                    isShowingEditor = true
                                },
                                onCreateRange: { start, end in
                                    createNewEntry(start: start, end: end)
                                },
                                onUpdateEntryTime: { entry, start, end in
                                    var updated = entry
                                    updated.startAt = start
                                    updated.endAt = end
                                    DatabaseManager.shared.updateEntry(updated)
                                    loadWeekEntries()
                                }
                            )
                        }
                    }
                }
                .padding(.bottom, 24)
            }
        }
        .background(Theme.bgDeep)
        .sheet(isPresented: $isShowingEditor) {
            EntryEditorPopover(
                entry: $selectedEntryForEdit,
                isPresented: $isShowingEditor,
                onSaved: {
                    loadWeekEntries()
                },
                onDeleted: {
                    loadWeekEntries()
                }
            )
        }
        .onAppear {
            loadWeekEntries()
        }
        .onReceive(NotificationCenter.default.publisher(for: DatabaseManager.didChangeNotification)) { _ in
            loadWeekEntries()
        }
    }
    
    // MARK: - Header Bar
    private var headerBar: some View {
        HStack(spacing: 16) {
            // Navigation arrows & Today button
            HStack(spacing: 6) {
                Button(action: {
                    navigateWeek(by: -1)
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.textSecondary)
                        .padding(7)
                        .background(Theme.bgSubtle)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .help("Previous week")
                
                Button(action: {
                    resetToToday()
                }) {
                    Text("Today")
                        .font(Theme.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.textPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Theme.bgSubtle)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    navigateWeek(by: 1)
                }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.textSecondary)
                        .padding(7)
                        .background(Theme.bgSubtle)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .help("Next week")
            }
            
            // Week Date Range Label
            Text(formattedWeekRange())
                .font(Theme.titleSmall)
                .foregroundColor(Theme.textPrimary)
            
            Spacer()
            
            // Total Weekly Hours Badge
            HStack(spacing: 6) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 11))
                Text("Total: \(totalWeeklyDurationFormatted)")
                    .font(Theme.monoBold)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Theme.accent.opacity(0.15))
            .foregroundColor(Theme.accentLight)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Theme.accent.opacity(0.3), lineWidth: 1)
            )
            
            // + Add Block Button
            Button(action: {
                selectedEntryForEdit = nil
                isShowingEditor = true
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                    Text("Add Block")
                        .font(Theme.caption)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Theme.accent)
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Theme.bgDark)
        .overlay(
            Rectangle()
                .fill(Theme.border)
                .frame(height: 1),
            alignment: .bottom
        )
    }
    
    // MARK: - Day Headers Row
    private var dayHeadersRow: some View {
        HStack(spacing: 0) {
            // Time gutter top spacing
            Rectangle()
                .fill(Theme.bgDark)
                .frame(width: 52, height: 50)
                .overlay(
                    Rectangle()
                        .fill(Theme.border)
                        .frame(width: 1),
                    alignment: .trailing
                )
            
            // 7 Day Header Columns
            HStack(spacing: 0) {
                ForEach(weekDays, id: \.self) { day in
                    let isToday = Calendar.current.isDateInToday(day)
                    let dayEntries = entriesForDay(day)
                    let totalMins = dayEntries.reduce(0) { $0 + $1.durationMinutes }
                    
                    VStack(spacing: 4) {
                        HStack(spacing: 6) {
                            Text(dayName(for: day))
                                .font(Theme.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(isToday ? Theme.accentLight : Theme.textSecondary)
                            
                            Text(dayNumber(for: day))
                                .font(Theme.bodyMedium)
                                .fontWeight(isToday ? .bold : .regular)
                                .foregroundColor(isToday ? .white : Theme.textPrimary)
                                .padding(.horizontal, isToday ? 6 : 0)
                                .padding(.vertical, isToday ? 2 : 0)
                                .background(isToday ? Theme.accent : Color.clear)
                                .clipShape(Capsule())
                        }
                        
                        if totalMins > 0 {
                            Text("\(totalMins / 60)h \(totalMins % 60)m")
                                .font(.system(size: 9, weight: .medium, design: .monospaced))
                                .foregroundColor(Theme.textMuted)
                        } else {
                            Text("—")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(Theme.textMuted.opacity(0.4))
                        }
                    }
                    .frame(minWidth: 140, maxWidth: .infinity)
                    .frame(height: 50)
                    .background(isToday ? Theme.accent.opacity(0.04) : Theme.bgDark)
                    .overlay(
                        Rectangle()
                            .fill(Theme.border)
                            .frame(width: 1),
                        alignment: .trailing
                    )
                }
            }
        }
        .background(Theme.bgDark)
        .overlay(
            Rectangle()
                .fill(Theme.border)
                .frame(height: 1),
            alignment: .bottom
        )
    }
    
    // MARK: - Helpers
    private func loadWeekEntries() {
        entries = DatabaseManager.shared.fetchForWeek(currentWeekStart)
    }
    
    private func entriesForDay(_ day: Date) -> [TimesheetEntry] {
        let cal = Calendar.current
        return entries.filter { cal.isDate($0.startAt, inSameDayAs: day) }
    }
    
    private func navigateWeek(by delta: Int) {
        if let next = Calendar.current.date(byAdding: .weekOfYear, value: delta, to: currentWeekStart) {
            currentWeekStart = next
            loadWeekEntries()
        }
    }
    
    private func resetToToday() {
        let cal = Calendar.current
        var comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        comps.weekday = 2
        if let start = cal.date(from: comps) {
            currentWeekStart = start
            loadWeekEntries()
        }
    }
    
    private func formattedWeekRange() -> String {
        let cal = Calendar.current
        guard let weekEnd = cal.date(byAdding: .day, value: 6, to: currentWeekStart) else { return "" }
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        let fEnd = DateFormatter()
        fEnd.dateFormat = "MMM d, yyyy"
        return "\(f.string(from: currentWeekStart)) – \(fEnd.string(from: weekEnd))"
    }
    
    private func dayName(for date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f.string(from: date).uppercased()
    }
    
    private func dayNumber(for date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f.string(from: date)
    }
    
    private func createNewEntry(start: Date, end: Date) {
        let isFuture = start > Date()
        let kind: EntryKind = isFuture ? .planned : .logged
        
        let newEntry = TimesheetEntry(
            kind: kind.rawValue,
            startAt: start,
            endAt: end,
            rawText: "New Task",
            inputMethod: InputMethod.typed.rawValue,
            category: "Coding",
            productivity: ProductivityType.productive.rawValue
        )
        
        selectedEntryForEdit = newEntry
        isShowingEditor = true
    }
}
