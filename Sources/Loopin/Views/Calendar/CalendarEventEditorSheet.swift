import SwiftUI

public struct CalendarEventEditorSheet: View {
    @ObservedObject var appState: AppState = .shared
    @ObservedObject var calendarManager: CalendarManager = .shared
    
    @Binding var event: CalendarEvent?
    @Binding var isPresented: Bool
    
    var initialStartDate: Date?
    var initialEndDate: Date?
    
    @State private var title: String = ""
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date()
    @State private var isAllDay: Bool = true
    @State private var selectedCalendarId: String = "planned"
    @State private var selectedColorHex: String = "#0288EB"
    @State private var location: String = ""
    @State private var notes: String = ""
    @State private var showDeleteConfirmation: Bool = false
    
    private let availableColors: [String] = [
        "#0288EB", // Google / Loopin Blue
        "#34A853", // Google Green
        "#8B5CF6", // Royal Violet
        "#EA4335", // Coral Red
        "#FBBC04", // Amber Yellow
        "#10B981", // Emerald
        "#EC4899", // Pink
        "#64748B"  // Slate Gray
    ]
    
    public init(
        event: Binding<CalendarEvent?>,
        isPresented: Binding<Bool>,
        initialStartDate: Date? = nil,
        initialEndDate: Date? = nil
    ) {
        self._event = event
        self._isPresented = isPresented
        self.initialStartDate = initialStartDate
        self.initialEndDate = initialEndDate
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack {
                Text(event == nil ? "Create Event" : "Edit Event")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
                
                Spacer()
                
                Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Theme.textMuted)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 12)
            
            Divider()
                .background(Theme.border)
            
            // Form Fields
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    // Event Title
                    VStack(alignment: .leading, spacing: 6) {
                        Text("EVENT TITLE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Theme.textMuted)
                            .tracking(0.6)
                        
                        TextField("Add title (e.g., Team Sprint Planning)", text: $title)
                            .textFieldStyle(.plain)
                            .font(.system(size: 14, weight: .medium))
                            .padding(10)
                            .background(Theme.bgSubtle)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Theme.border, lineWidth: 1)
                            )
                    }
                    
                    // All Day Toggle
                    Toggle(isOn: $isAllDay) {
                        Text("All-day Event")
                            .font(.system(size: 12.5, weight: .medium))
                            .foregroundColor(Theme.textPrimary)
                    }
                    .toggleStyle(.switch)
                    
                    // Dates Row
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("START")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Theme.textMuted)
                                .tracking(0.6)
                            
                            DatePicker(
                                "",
                                selection: $startDate,
                                displayedComponents: isAllDay ? [.date] : [.date, .hourAndMinute]
                            )
                            .labelsHidden()
                            .datePickerStyle(.compact)
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("END")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Theme.textMuted)
                                .tracking(0.6)
                            
                            DatePicker(
                                "",
                                selection: $endDate,
                                displayedComponents: isAllDay ? [.date] : [.date, .hourAndMinute]
                            )
                            .labelsHidden()
                            .datePickerStyle(.compact)
                        }
                    }
                    
                    // Calendar Category & Color Row
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("CALENDAR")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Theme.textMuted)
                                .tracking(0.6)
                            
                            Picker("", selection: $selectedCalendarId) {
                                Text("Pre-planned").tag("planned")
                                Text("Log Sheet").tag("logged")
                                Text(appState.googleUserEmail.isEmpty ? "atharavnarang05@gmail.com" : appState.googleUserEmail).tag("google")
                            }
                            .pickerStyle(.menu)
                            .labelsHidden()
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("EVENT COLOR")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Theme.textMuted)
                                .tracking(0.6)
                            
                            HStack(spacing: 6) {
                                ForEach(availableColors, id: \.self) { colorHex in
                                    Circle()
                                        .fill(Color(hex: colorHex))
                                        .frame(width: 18, height: 18)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: selectedColorHex == colorHex ? 2 : 0)
                                        )
                                        .shadow(color: Color.black.opacity(0.2), radius: 1)
                                        .onTapGesture {
                                            selectedColorHex = colorHex
                                        }
                                }
                            }
                        }
                    }
                    
                    // Location
                    VStack(alignment: .leading, spacing: 6) {
                        Text("LOCATION (OPTIONAL)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Theme.textMuted)
                            .tracking(0.6)
                        
                        TextField("Google Meet, Office, etc.", text: $location)
                            .textFieldStyle(.plain)
                            .font(.system(size: 12.5))
                            .padding(8)
                            .background(Theme.bgSubtle)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Theme.border, lineWidth: 1)
                            )
                    }
                    
                    // Notes
                    VStack(alignment: .leading, spacing: 6) {
                        Text("NOTES / DESCRIPTION")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Theme.textMuted)
                            .tracking(0.6)
                        
                        TextEditor(text: $notes)
                            .font(.system(size: 12))
                            .frame(height: 60)
                            .padding(6)
                            .background(Theme.bgSubtle)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Theme.border, lineWidth: 1)
                            )
                    }
                }
                .padding(20)
            }
            
            Divider()
                .background(Theme.border)
            
            // Footer Action Buttons
            HStack {
                if event != nil {
                    Button(action: {
                        showDeleteConfirmation = true
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "trash")
                            Text("Delete")
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.wasteful)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Theme.wastefulBg)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                    .confirmationDialog("Are you sure you want to delete this event?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                        Button("Delete Event", role: .destructive) {
                            if let ev = event {
                                calendarManager.deleteEvent(id: ev.id)
                            }
                            isPresented = false
                        }
                        Button("Cancel", role: .cancel) {}
                    }
                }
                
                Spacer()
                
                Button(action: {
                    isPresented = false
                }) {
                    Text("Cancel")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.textSecondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Theme.bgSubtle)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                
                Button(action: saveEvent) {
                    Text("Save Event")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 7)
                        .background(Theme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
        .frame(width: 440, height: 500)
        .background(Theme.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.border, lineWidth: 1)
        )
        .onAppear {
            initializeFields()
        }
    }
    
    private func initializeFields() {
        if let ev = event {
            title = ev.title
            startDate = ev.startDate
            endDate = ev.endDate
            isAllDay = ev.isAllDay
            selectedCalendarId = ev.calendarId
            selectedColorHex = ev.colorHex
            location = ev.location ?? ""
            notes = ev.notes ?? ""
        } else {
            let start = initialStartDate ?? Date()
            let end = initialEndDate ?? Calendar.current.date(byAdding: .hour, value: 1, to: start) ?? start
            startDate = start
            endDate = max(start, end)
            isAllDay = true
            selectedColorHex = Theme.accent.toHex()
        }
    }
    
    private func saveEvent() {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else { return }
        
        // Ensure endDate >= startDate
        let finalEnd = max(startDate, endDate)
        
        if var existing = event {
            existing.title = cleanTitle
            existing.startDate = startDate
            existing.endDate = finalEnd
            existing.isAllDay = isAllDay
            existing.calendarId = selectedCalendarId
            existing.colorHex = selectedColorHex
            existing.location = location.isEmpty ? nil : location
            existing.notes = notes.isEmpty ? nil : notes
            calendarManager.updateEvent(existing)
        } else {
            let newEvent = CalendarEvent(
                title: cleanTitle,
                startDate: startDate,
                endDate: finalEnd,
                isAllDay: isAllDay,
                calendarId: selectedCalendarId,
                colorHex: selectedColorHex,
                location: location.isEmpty ? nil : location,
                notes: notes.isEmpty ? nil : notes
            )
            calendarManager.addEvent(newEvent)
        }
        
        isPresented = false
    }
}
