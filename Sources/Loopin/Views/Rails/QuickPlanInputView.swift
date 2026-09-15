import SwiftUI

public struct QuickPlanInputView: View {
    @State private var inputText: String = ""
    @State private var isListening: Bool = false
    @State private var isHovered: Bool = false
    @State private var justAdded: Bool = false
    
    var onAdded: (() -> Void)?
    
    public init(onAdded: (() -> Void)? = nil) {
        self.onAdded = onAdded
    }
    
    public var body: some View {
        HStack(spacing: 12) {
            // Badge
            HStack(spacing: 4) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 11, weight: .bold))
                Text("PLANNED")
                    .font(Theme.caption)
                    .fontWeight(.bold)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Theme.plannedBg)
            .foregroundColor(Theme.planned)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Theme.planned.opacity(0.3), lineWidth: 1)
            )
            
            // Text field
            TextField("What do you plan to work on? (e.g. 'Coding 2-4pm', 'Team Standup 10am')...", text: $inputText)
                .textFieldStyle(.plain)
                .font(Theme.bodyMedium)
                .foregroundColor(Theme.textPrimary)
                .onSubmit {
                    submitPlan()
                }
            
            // Voice Mic button
            Button(action: {
                toggleVoiceInput()
            }) {
                Image(systemName: isListening ? "mic.fill" : "mic")
                    .font(.system(size: 14))
                    .foregroundColor(isListening ? Theme.wasteful : Theme.textSecondary)
                    .padding(8)
                    .background(isListening ? Theme.wastefulBg : Theme.bgSubtle)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .help("Voice input")
            
            // Submit button
            Button(action: {
                submitPlan()
            }) {
                Image(systemName: justAdded ? "checkmark" : "arrow.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(justAdded ? Theme.productive : .white)
                    .frame(width: 32, height: 32)
                    .background(justAdded ? Theme.productiveBg : (inputText.isEmpty ? Theme.bgSubtle : Theme.accent))
                    .clipShape(Circle())
                    .shadow(color: inputText.isEmpty ? Color.clear : Theme.accentGlow, radius: 6)
            }
            .buttonStyle(.plain)
            .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .help("Add planned block (Enter)")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .glassCard(cornerRadius: 14, strokeColor: isHovered ? Theme.accent.opacity(0.4) : Theme.border)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
    
    private func submitPlan() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        // Parse natural language task & time
        let parsed = NaturalLanguageParser.parse(text: text)
        
        // Auto-classify category & productivity
        let rules = DatabaseManager.shared.fetchAllRules()
        let match = ClassifierEngine.classify(text: parsed.title, rules: rules)
        
        let entry = TimesheetEntry(
            kind: EntryKind.planned.rawValue,
            startAt: parsed.startAt,
            endAt: parsed.endAt,
            rawText: parsed.title,
            inputMethod: isListening ? InputMethod.voice.rawValue : InputMethod.typed.rawValue,
            category: match?.category ?? "Planning",
            subcategory: match?.subcategory,
            productivity: match?.productivity.rawValue ?? ProductivityType.productive.rawValue
        )
        
        DatabaseManager.shared.insertEntry(entry)
        
        // Trigger visual feedback
        inputText = ""
        isListening = false
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            justAdded = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation {
                justAdded = false
            }
        }
        
        onAdded?()
    }
    
    private func toggleVoiceInput() {
        isListening.toggle()
        if isListening {
            // Simulated speech sample for swift testing
            inputText = "Design review 3pm to 4:30pm"
        }
    }
}
