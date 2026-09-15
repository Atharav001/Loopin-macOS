import SwiftUI

public struct RuleEditorSheet: View {
    @Binding var rule: ClassificationRule?
    @Binding var isPresented: Bool
    
    @State private var phrase: String = ""
    @State private var category: String = "Coding"
    @State private var subcategory: String = ""
    @State private var productivity: ProductivityType = .productive
    
    var onSaved: (() -> Void)?
    var onDeleted: (() -> Void)?
    
    public init(
        rule: Binding<ClassificationRule?>,
        isPresented: Binding<Bool>,
        onSaved: (() -> Void)? = nil,
        onDeleted: (() -> Void)? = nil
    ) {
        self._rule = rule
        self._isPresented = isPresented
        self.onSaved = onSaved
        self.onDeleted = onDeleted
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "character.book.closed.fill")
                        .foregroundColor(Theme.accentLight)
                    Text(rule == nil ? "New Classification Rule" : "Edit Classification Rule")
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
            
            // Phrase Match Input
            VStack(alignment: .leading, spacing: 4) {
                Text("Keyword / Phrase to match")
                    .font(Theme.caption)
                    .foregroundColor(Theme.textSecondary)
                
                TextField("e.g. 'youtube shorts', 'swift ui', 'code review'", text: $phrase)
                    .textFieldStyle(.plain)
                    .font(Theme.bodyMedium)
                    .padding(8)
                    .background(Theme.bgDark)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Theme.border, lineWidth: 1)
                    )
                
                Text("Any logged text containing this phrase will automatically be categorized.")
                    .font(.system(size: 10))
                    .foregroundColor(Theme.textMuted)
            }
            
            // Category & Productivity Pickers
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Category")
                        .font(Theme.caption)
                        .foregroundColor(Theme.textSecondary)
                    
                    Picker("", selection: $category) {
                        ForEach(CategoryPreset.defaults) { preset in
                            Text(preset.name).tag(preset.name)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(4)
                    .background(Theme.bgDark)
                    .cornerRadius(6)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.border, lineWidth: 1))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Productivity")
                        .font(Theme.caption)
                        .foregroundColor(Theme.textSecondary)
                    
                    Picker("", selection: $productivity) {
                        ForEach(ProductivityType.allCases, id: \.self) { p in
                            Text(p.displayName).tag(p)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(4)
                    .background(Theme.bgDark)
                    .cornerRadius(6)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.border, lineWidth: 1))
                }
            }
            
            Divider().background(Theme.border)
            
            // Actions
            HStack {
                if rule != nil {
                    Button(role: .destructive, action: {
                        if let r = rule {
                            DatabaseManager.shared.deleteRule(id: r.id)
                            onDeleted?()
                        }
                        isPresented = false
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "trash")
                            Text("Delete Rule")
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
                    saveRule()
                }) {
                    Text("Save Rule")
                        .font(Theme.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Theme.accent)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .disabled(phrase.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 380)
        .background(Theme.bgCard)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Theme.borderHighlight, lineWidth: 1)
        )
        .onAppear {
            if let existing = rule {
                phrase = existing.phrase
                category = existing.category
                subcategory = existing.subcategory ?? ""
                productivity = existing.productivityType
            } else {
                phrase = ""
                category = "Coding"
                subcategory = ""
                productivity = .productive
            }
        }
    }
    
    private func saveRule() {
        let p = phrase.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !p.isEmpty else { return }
        
        let newOrUpdated = ClassificationRule(
            id: rule?.id ?? UUID().uuidString,
            phrase: p,
            category: category,
            subcategory: subcategory.isEmpty ? nil : subcategory,
            productivity: productivity.rawValue,
            updatedAt: Date()
        )
        
        DatabaseManager.shared.insertRule(newOrUpdated)
        isPresented = false
        onSaved?()
    }
}
