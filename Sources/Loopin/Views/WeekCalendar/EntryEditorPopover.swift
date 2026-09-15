import SwiftUI

public struct EntryEditorPopover: View {
    @Binding var entry: TimesheetEntry?
    @Binding var isPresented: Bool
    
    @State private var rawText: String = ""
    @State private var kind: EntryKind = .logged
    @State private var startAt: Date = Date()
    @State private var endAt: Date = Date().addingTimeInterval(3600)
    @State private var selectedCategory: String = "Coding"
    @State private var selectedProductivity: ProductivityType = .productive
    
    var onSaved: (() -> Void)?
    var onDeleted: (() -> Void)?
    
    public init(
        entry: Binding<TimesheetEntry?>,
        isPresented: Binding<Bool>,
        onSaved: (() -> Void)? = nil,
        onDeleted: (() -> Void)? = nil
    ) {
        self._entry = entry
        self._isPresented = isPresented
        self.onSaved = onSaved
        self.onDeleted = onDeleted
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: entry == nil ? "plus.circle.fill" : "pencil.circle.fill")
                        .foregroundColor(Theme.accentLight)
                    Text(entry == nil ? "New Timesheet Entry" : "Edit Timesheet Entry")
                        .font(Theme.titleSmall)
                        .foregroundColor(Theme.textPrimary)
                }
                
                Spacer()
                
                Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Theme.textSecondary)
                        .padding(5)
                        .background(Theme.bgSubtle)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            
            Divider().background(Theme.border)
            
            // Title Field
            VStack(alignment: .leading, spacing: 4) {
                Text("Activity Description")
                    .font(Theme.caption)
                    .foregroundColor(Theme.textSecondary)
                
                TextField("e.g. Building native AppKit window", text: $rawText)
                    .textFieldStyle(.plain)
                    .font(Theme.bodyMedium)
                    .padding(8)
                    .background(Theme.bgDark)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Theme.border, lineWidth: 1)
                    )
            }
            
            // Kind Selector
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Entry Type")
                        .font(Theme.caption)
                        .foregroundColor(Theme.textSecondary)
                    
                    Picker("", selection: $kind) {
                        ForEach(EntryKind.allCases, id: \.self) { k in
                            Text(k.displayName).tag(k)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            
            // Time Range
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Start Time")
                        .font(Theme.caption)
                        .foregroundColor(Theme.textSecondary)
                    DatePicker("", selection: $startAt, displayedComponents: [.hourAndMinute])
                        .labelsHidden()
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("End Time")
                        .font(Theme.caption)
                        .foregroundColor(Theme.textSecondary)
                    DatePicker("", selection: $endAt, displayedComponents: [.hourAndMinute])
                        .labelsHidden()
                }
            }
            
            // Category Selection (Clean clickable chips)
            VStack(alignment: .leading, spacing: 6) {
                Text("Category")
                    .font(Theme.caption)
                    .foregroundColor(Theme.textSecondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(CategoryPreset.defaults) { preset in
                            let isSelected = selectedCategory == preset.name
                            Button(action: {
                                selectedCategory = preset.name
                            }) {
                                Text(preset.name)
                                    .font(.system(size: 11, weight: isSelected ? .semibold : .medium))
                                    .foregroundColor(isSelected ? .white : Theme.textSecondary)
                                    .padding(.horizontal, 9)
                                    .padding(.vertical, 4.5)
                                    .background(isSelected ? Theme.accent : Theme.bgDark)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(isSelected ? Theme.accent : Theme.border, lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            
            // Productivity Selection (Segmented color chips)
            VStack(alignment: .leading, spacing: 6) {
                Text("Productivity Assessment")
                    .font(Theme.caption)
                    .foregroundColor(Theme.textSecondary)
                
                HStack(spacing: 8) {
                    ForEach(ProductivityType.allCases, id: \.self) { p in
                        let isSelected = selectedProductivity == p
                        let color = Color.forProductivity(p)
                        
                        Button(action: {
                            selectedProductivity = p
                        }) {
                            HStack(spacing: 5) {
                                Circle()
                                    .fill(color)
                                    .frame(width: 7, height: 7)
                                Text(p.displayName)
                                    .font(.system(size: 11, weight: isSelected ? .semibold : .medium))
                                    .foregroundColor(isSelected ? .white : Theme.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(isSelected ? color.opacity(0.25) : Theme.bgDark)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(isSelected ? color : Theme.border, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            Divider().background(Theme.border)
            
            // Actions
            HStack {
                if entry != nil {
                    Button(role: .destructive, action: {
                        if let e = entry {
                            DatabaseManager.shared.deleteEntry(id: e.id)
                            onDeleted?()
                        }
                        isPresented = false
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "trash")
                            Text("Delete")
                        }
                        .font(Theme.caption)
                        .foregroundColor(Theme.wasteful)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Theme.wastefulBg)
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
                
                Button(action: {
                    isPresented = false
                }) {
                    Text("Cancel")
                        .font(Theme.caption)
                        .foregroundColor(Theme.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    saveEntry()
                }) {
                    Text("Save Entry")
                        .font(Theme.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Theme.accent)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .disabled(rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(22)
        .frame(width: 420)
        .background(Theme.bgCard)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Theme.borderHighlight, lineWidth: 1)
        )
        .onAppear {
            if let existing = entry {
                rawText = existing.rawText
                kind = existing.entryKind
                startAt = existing.startAt
                endAt = existing.endAt
                selectedCategory = existing.category ?? "Coding"
                selectedProductivity = existing.productivityType ?? .productive
            } else {
                rawText = ""
                kind = .logged
                startAt = Date()
                endAt = Date().addingTimeInterval(1800)
                selectedCategory = "Coding"
                selectedProductivity = .productive
            }
        }
    }
    
    private func saveEntry() {
        let title = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        
        var targetEnd = endAt
        if targetEnd <= startAt {
            targetEnd = startAt.addingTimeInterval(900)
        }
        
        let newOrUpdated = TimesheetEntry(
            id: entry?.id ?? UUID().uuidString,
            kind: kind.rawValue,
            startAt: startAt,
            endAt: targetEnd,
            rawText: title,
            inputMethod: entry?.inputMethod ?? InputMethod.typed.rawValue,
            category: selectedCategory,
            productivity: selectedProductivity.rawValue,
            updatedAt: Date()
        )
        
        DatabaseManager.shared.insertEntry(newOrUpdated)
        
        // Auto-learn rule for persistent classification
        ClassifierEngine.learnRule(
            for: title,
            category: selectedCategory,
            productivity: selectedProductivity
        )
        
        isPresented = false
        onSaved?()
    }
}
