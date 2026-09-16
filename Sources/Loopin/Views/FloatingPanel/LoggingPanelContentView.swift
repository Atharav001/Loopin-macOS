import SwiftUI

public struct LoggingPanelContentView: View {
    @ObservedObject var appState: AppState = .shared
    @State private var inputText: String = ""
    @State private var selectedCategory: String? = nil
    @State private var isListening: Bool = false
    @State private var isSubmitted: Bool = false
    @State private var rippleTrigger: Bool = false
    
    var onDismiss: (() -> Void)?
    
    private let quickSuggestions = ["Coding", "Deep Work", "Meeting", "Planning", "Research", "YouTube Watching", "Gaming", "Break"]
    
    public init(onDismiss: (() -> Void)? = nil) {
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        ZStack {
            Theme.bgDeep
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 14) {
                // Header
                HStack {
                    HStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(Theme.accent.opacity(0.2))
                                .frame(width: 20, height: 20)
                            Circle()
                                .fill(Theme.accent)
                                .frame(width: 7, height: 7)
                        }
                        
                        Text("What did you work on?")
                            .font(Theme.titleSmall)
                            .foregroundColor(Theme.textPrimary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 9))
                        Text(formattedTimeInterval)
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    }
                    .foregroundColor(Theme.accentLight)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3.5)
                    .background(Theme.accent.opacity(0.15))
                    .cornerRadius(6)
                    
                    Button(action: {
                        dismissPanel()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Theme.textMuted)
                            .padding(4)
                            .background(Theme.bgSubtle)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                
                // Text Input Field with Voice Mic
                HStack(spacing: 8) {
                    TextField("e.g. Debugging database query...", text: $inputText)
                        .textFieldStyle(.plain)
                        .font(Theme.bodyMedium)
                        .foregroundColor(Theme.textPrimary)
                        .onSubmit {
                            submitLog()
                        }
                    
                    Button(action: {
                        toggleVoiceInput()
                    }) {
                        Image(systemName: isListening ? "mic.fill" : "mic")
                            .font(.system(size: 13))
                            .foregroundColor(isListening ? Theme.wasteful : Theme.textSecondary)
                            .padding(6)
                            .background(isListening ? Theme.wastefulBg : Theme.bgSubtle)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .help("Voice input")
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Theme.bgDark)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Theme.borderHighlight, lineWidth: 1)
                )
                
                // Quick Category Chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(quickSuggestions, id: \.self) { cat in
                            let isSelected = selectedCategory == cat
                            Button(action: {
                                selectedCategory = isSelected ? nil : cat
                                if inputText.isEmpty {
                                    inputText = cat
                                }
                            }) {
                                Text(cat)
                                    .font(Theme.caption)
                                    .fontWeight(isSelected ? .semibold : .regular)
                                    .foregroundColor(isSelected ? .white : Theme.textSecondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(isSelected ? Theme.accent : Theme.bgSubtle)
                                    .cornerRadius(6)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(isSelected ? Theme.accentLight : Theme.border, lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                Divider().background(Theme.border)
                
                // Action Buttons: Skip vs Log
                HStack {
                    Button(action: {
                        skipLog()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 10))
                            Text("Skip")
                                .font(Theme.caption)
                        }
                        .foregroundColor(Theme.textMuted)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Theme.bgSubtle)
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    Button(action: {
                        submitLog()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: isSubmitted ? "checkmark" : "arrow.right")
                                .font(.system(size: 11, weight: .bold))
                            Text("Log Activity")
                                .font(Theme.caption)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(isSubmitted ? Theme.productive : Theme.accent)
                        .cornerRadius(6)
                        .shadow(color: Theme.accentGlow, radius: 4)
                    }
                    .buttonStyle(.plain)
                    .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(18)
        }
        .frame(width: 380, height: 200)
        .breathingGlow(active: !isSubmitted)
        .rippleConfirm(trigger: rippleTrigger)
    }
    
    private func submitLog() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        let now = Date()
        let intervalSecs = Double(appState.selectedIntervalMinutes * 60)
        let start = appState.promptIntervalStart ?? now.addingTimeInterval(-intervalSecs)
        let end = appState.promptIntervalEnd ?? now
        
        // Auto-classify
        let rules = DatabaseManager.shared.fetchAllRules()
        let match = ClassifierEngine.classify(text: text, rules: rules)
        let category = selectedCategory ?? match?.category ?? "General"
        let prod = match?.productivity ?? ProductivityType.productive
        
        let entry = TimesheetEntry(
            kind: EntryKind.logged.rawValue,
            startAt: start,
            endAt: end,
            rawText: text,
            inputMethod: isListening ? InputMethod.voice.rawValue : InputMethod.typed.rawValue,
            category: category,
            subcategory: match?.subcategory,
            productivity: prod.rawValue
        )
        
        DatabaseManager.shared.insertEntry(entry)
        
        // Trigger breathing glowing celebration effect around the window
        appState.triggerCelebration(color: prod == .productive ? Theme.productive : Theme.accent)
        
        // Learn rule automatically
        ClassifierEngine.learnRule(for: text, category: category, productivity: prod)
        
        withAnimation(.easeOut(duration: 0.3)) {
            isSubmitted = true
            rippleTrigger = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            dismissPanel()
        }
    }
    
    private func skipLog() {
        let now = Date()
        let intervalSecs = Double(appState.selectedIntervalMinutes * 60)
        let start = appState.promptIntervalStart ?? now.addingTimeInterval(-intervalSecs)
        let end = appState.promptIntervalEnd ?? now
        
        let entry = TimesheetEntry(
            kind: EntryKind.logged.rawValue,
            startAt: start,
            endAt: end,
            rawText: "Skipped Interval",
            inputMethod: InputMethod.skipped.rawValue,
            category: "Break",
            productivity: ProductivityType.neutral.rawValue
        )
        
        DatabaseManager.shared.insertEntry(entry)
        dismissPanel()
    }
    
    private func toggleVoiceInput() {
        isListening.toggle()
        if isListening {
            inputText = "Pair programming on SwiftUI"
        }
    }
    
    private var formattedTimeInterval: String {
        return appState.formattedCurrentPromptInterval
    }
    
    private func dismissPanel() {
        appState.showFloatingLoggingPanel = false
        onDismiss?()
    }
}
