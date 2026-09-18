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
    @State private var linkUrl: String = ""
    @State private var documentPath: String = ""
    @State private var isDocumentReference: Bool = false
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
                            .frame(height: 55)
                            .padding(6)
                            .background(Theme.bgSubtle)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Theme.border, lineWidth: 1)
                            )
                    }
                    
                    // Link / URL Section
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("LINK / URL")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Theme.textMuted)
                                .tracking(0.6)
                            
                            Spacer()
                            
                            if let url = URL(string: linkUrl.trimmingCharacters(in: .whitespacesAndNewlines)),
                               url.scheme != nil {
                                Button(action: {
                                    NSWorkspace.shared.open(url)
                                }) {
                                    HStack(spacing: 3) {
                                        Text("Open Link")
                                            .font(.system(size: 10, weight: .semibold))
                                        Image(systemName: "arrow.up.right.square")
                                            .font(.system(size: 9))
                                    }
                                    .foregroundColor(Theme.accent)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        HStack(spacing: 6) {
                            Image(systemName: "link")
                                .font(.system(size: 11))
                                .foregroundColor(Theme.textMuted)
                            
                            TextField("https://example.com or meeting link", text: $linkUrl)
                                .textFieldStyle(.plain)
                                .font(.system(size: 12.5))
                        }
                        .padding(8)
                        .background(Theme.bgSubtle)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Theme.border, lineWidth: 1)
                        )
                    }
                    
                    // Document / File Reference Section
                    VStack(alignment: .leading, spacing: 6) {
                        Text("DOCUMENT / FILE ATTACHMENT")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Theme.textMuted)
                            .tracking(0.6)
                        
                        if !documentPath.isEmpty {
                            HStack(spacing: 8) {
                                Image(systemName: "doc.text.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(Theme.accent)
                                
                                Text(URL(fileURLWithPath: documentPath).lastPathComponent)
                                    .font(.system(size: 11.5, weight: .medium))
                                    .foregroundColor(Theme.textPrimary)
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                Button(action: {
                                    let url = URL(fileURLWithPath: documentPath)
                                    NSWorkspace.shared.open(url)
                                }) {
                                    Text("Open")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(Theme.accent)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Theme.accent.opacity(0.12))
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                                
                                Button(action: {
                                    documentPath = ""
                                }) {
                                    Image(systemName: "xmark.circle")
                                        .font(.system(size: 11))
                                        .foregroundColor(Theme.wasteful)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(8)
                            .background(Theme.bgSubtle)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Theme.accent.opacity(0.3), lineWidth: 1)
                            )
                        } else {
                            Button(action: chooseDocument) {
                                HStack(spacing: 6) {
                                    Image(systemName: "paperclip")
                                        .font(.system(size: 11, weight: .semibold))
                                    Text("Attach File or Text Document...")
                                        .font(.system(size: 11.5, weight: .medium))
                                }
                                .foregroundColor(Theme.textSecondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Theme.bgSubtle)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Theme.border, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    // Reference Option Toggle
                    Toggle(isOn: $isDocumentReference) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Pin as Document / Reference Note")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Theme.textPrimary)
                            Text("Displays as a document reference badge on the calendar day")
                                .font(.system(size: 10))
                                .foregroundColor(Theme.textMuted)
                        }
                    }
                    .toggleStyle(.switch)
                    .padding(.top, 2)
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
                    Text(isDocumentReference ? "Save Reference" : "Save Event")
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
        .frame(width: 460, height: 570)
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
    
    private func chooseDocument() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.prompt = "Attach File"
        if panel.runModal() == .OK, let url = panel.url {
            documentPath = url.path
            if title.isEmpty {
                title = url.deletingPathExtension().lastPathComponent
            }
            isDocumentReference = true
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
            linkUrl = ev.linkUrl ?? ""
            documentPath = ev.documentPath ?? ""
            isDocumentReference = ev.isDocumentReference
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
        let cleanLink = linkUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanDoc = documentPath.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if var existing = event {
            existing.title = cleanTitle
            existing.startDate = startDate
            existing.endDate = finalEnd
            existing.isAllDay = isAllDay
            existing.calendarId = selectedCalendarId
            existing.colorHex = selectedColorHex
            existing.location = location.isEmpty ? nil : location
            existing.notes = notes.isEmpty ? nil : notes
            existing.linkUrl = cleanLink.isEmpty ? nil : cleanLink
            existing.documentPath = cleanDoc.isEmpty ? nil : cleanDoc
            existing.isDocumentReference = isDocumentReference
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
                notes: notes.isEmpty ? nil : notes,
                linkUrl: cleanLink.isEmpty ? nil : cleanLink,
                documentPath: cleanDoc.isEmpty ? nil : cleanDoc,
                isDocumentReference: isDocumentReference
            )
            calendarManager.addEvent(newEvent)
        }
        
        isPresented = false
    }
}
