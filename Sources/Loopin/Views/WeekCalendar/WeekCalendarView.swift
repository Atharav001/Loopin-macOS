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
        GeometryReader { geo in
            let gutterWidth: CGFloat = 56
            let availableWidth = max(700, geo.size.width - gutterWidth)
            let colWidth = floor(availableWidth / 7.0)
            let totalContentWidth = gutterWidth + colWidth * 7.0
            
            VStack(spacing: 0) {
                // Week Header Bar
                headerBar
                
                // 7 Day Headers Row (Pixel-perfect width matching grid columns)
                dayHeadersRow(gutterWidth: gutterWidth, colWidth: colWidth)
                
                // Vertical Scrollable Grid
                ScrollView(.vertical, showsIndicators: true) {
                    HStack(alignment: .top, spacing: 0) {
                        // Time Gutter (00:00 - 23:00 or 12 AM - 11 PM)
                        TimeGutterView(hourHeight: hourHeight, use24HourClock: appState.use24HourClock)
                            .frame(width: gutterWidth)
                        
                        // 7 Day Columns
                        HStack(spacing: 0) {
                            ForEach(weekDays, id: \.self) { day in
                                let dayEntries = entriesForDay(day)
                                let isToday = Calendar.current.isDateInToday(day)
                                
                                DayColumnView(
                                    date: day,
                                    entries: dayEntries,
                                    hourHeight: hourHeight,
                                    columnWidth: colWidth,
                                    isToday: isToday,
                                    use24HourClock: appState.use24HourClock,
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
                                .frame(width: colWidth)
                            }
                        }
                    }
                    .frame(width: totalContentWidth, alignment: .topLeading)
                    .padding(.bottom, 24)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
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
        HStack(spacing: 14) {
            // Navigation arrows & Today button
            HStack(spacing: 4) {
                Button(action: {
                    navigateWeek(by: -1)
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Theme.textSecondary)
                        .frame(width: 26, height: 26)
                        .background(Theme.bgSubtle)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .help("Previous week")
                
                Button(action: {
                    resetToToday()
                }) {
                    Text("Today")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)
                        .padding(.horizontal, 9)
                        .frame(height: 26)
                        .background(Theme.bgSubtle)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    navigateWeek(by: 1)
                }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Theme.textSecondary)
                        .frame(width: 26, height: 26)
                        .background(Theme.bgSubtle)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .help("Next week")
            }
            
            // Week Date Range Label
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.accentLight)
                Text(formattedWeekRange())
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
            }
            
            Spacer()
            
            // Clockify 12h / 24h Clock Toggle
            HStack(spacing: 2) {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        appState.use24HourClock = false
                    }
                }) {
                    Text("12h")
                        .font(.system(size: 10.5, weight: !appState.use24HourClock ? .bold : .medium))
                        .foregroundColor(!appState.use24HourClock ? .white : Theme.textMuted)
                        .padding(.horizontal, 7)
                        .frame(height: 22)
                        .background(!appState.use24HourClock ? Theme.accent : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .buttonStyle(.plain)
                .help("12-hour AM/PM clock")
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        appState.use24HourClock = true
                    }
                }) {
                    Text("24h")
                        .font(.system(size: 10.5, weight: appState.use24HourClock ? .bold : .medium))
                        .foregroundColor(appState.use24HourClock ? .white : Theme.textMuted)
                        .padding(.horizontal, 7)
                        .frame(height: 22)
                        .background(appState.use24HourClock ? Theme.accent : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .buttonStyle(.plain)
                .help("24-hour military clock")
            }
            .padding(2)
            .background(Theme.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Theme.border, lineWidth: 1)
            )
            
            // Total Weekly Hours Badge
            HStack(spacing: 5) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 10))
                    .foregroundColor(Theme.accentLight)
                Text("Total: \(totalWeeklyDurationFormatted)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.accentLight)
            }
            .padding(.horizontal, 9)
            .frame(height: 26)
            .background(Theme.accent.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Theme.accent.opacity(0.25), lineWidth: 1)
            )
            
            // + Add Block Button
            Button(action: {
                selectedEntryForEdit = nil
                isShowingEditor = true
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .bold))
                    Text("Add Block")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 11)
                .frame(height: 26)
                .background(Theme.accent)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .shadow(color: Theme.accent.opacity(0.25), radius: 4, y: 1)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Theme.bgDark)
        .overlay(
            Rectangle()
                .fill(Theme.border)
                .frame(height: 1),
            alignment: .bottom
        )
    }
    
    // MARK: - Day Headers Row
    private func dayHeadersRow(gutterWidth: CGFloat, colWidth: CGFloat) -> some View {
        HStack(spacing: 0) {
            // Time gutter top spacing (matches gutterWidth exactly)
            Rectangle()
                .fill(Theme.bgDark)
                .frame(width: gutterWidth, height: 54)
                .overlay(
                    Rectangle()
                        .fill(Theme.border)
                        .frame(width: 1),
                    alignment: .trailing
                )
            
            // 7 Day Header Columns (matches colWidth exactly)
            HStack(spacing: 0) {
                ForEach(weekDays, id: \.self) { day in
                    let isToday = Calendar.current.isDateInToday(day)
                    let dayEntries = entriesForDay(day)
                    let totalMins = dayEntries.reduce(0) { $0 + $1.durationMinutes }
                    
                    VStack(spacing: 3) {
                        // Day name (e.g. MON)
                        Text(dayName(for: day))
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(isToday ? Theme.accentLight : Theme.textSecondary)
                            .tracking(0.6)
                        
                        // Day number with circular highlight for today
                        if isToday {
                            Text(dayNumber(for: day))
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(width: 22, height: 22)
                                .background(Theme.accent)
                                .clipShape(Circle())
                        } else {
                            Text(dayNumber(for: day))
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundColor(Theme.textPrimary)
                                .frame(height: 22)
                        }
                        
                        // Day total duration
                        if totalMins > 0 {
                            Text("\(totalMins / 60)h \(totalMins % 60)m")
                                .font(.system(size: 9, weight: .medium, design: .monospaced))
                                .foregroundColor(isToday ? Theme.accentLight : Theme.textMuted)
                        } else {
                            Text("—")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(Theme.textMuted.opacity(0.4))
                        }
                    }
                    .frame(width: colWidth, height: 54)
                    .background(isToday ? Theme.accent.opacity(0.05) : Theme.bgDark)
                    .overlay(
                        Rectangle()
                            .fill(Theme.border)
                            .frame(width: 1),
                        alignment: .trailing
                    )
                }
            }
        }
        .frame(width: gutterWidth + colWidth * 7.0, alignment: .leading)
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
            rawText: "",
            inputMethod: InputMethod.typed.rawValue,
            category: "Coding",
            productivity: ProductivityType.productive.rawValue
        )
        
        selectedEntryForEdit = newEntry
        isShowingEditor = true
    }
}
