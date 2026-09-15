import SwiftUI

public struct DictionaryView: View {
    @State private var rules: [ClassificationRule] = []
    @State private var searchText: String = ""
    @State private var selectedFilter: ProductivityFilter = .all
    @State private var editingRule: ClassificationRule?
    @State private var isShowingEditor: Bool = false
    @State private var hoveredRuleId: String?
    
    private enum ProductivityFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case productive = "Productive"
        case neutral = "Neutral"
        case wasteful = "Wasteful"
        
        var id: String { rawValue }
    }
    
    public init() {}
    
    private var filteredRules: [ClassificationRule] {
        rules.filter { rule in
            let matchesSearch = searchText.isEmpty ||
                rule.phrase.localizedCaseInsensitiveContains(searchText) ||
                rule.category.localizedCaseInsensitiveContains(searchText)
            
            let matchesFilter: Bool
            switch selectedFilter {
            case .all: matchesFilter = true
            case .productive: matchesFilter = rule.productivity == "productive"
            case .neutral: matchesFilter = rule.productivity == "neutral"
            case .wasteful: matchesFilter = rule.productivity == "wasteful"
            }
            
            return matchesSearch && matchesFilter
        }
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            headerBar
            
            // Rules List Content
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 16) {
                    if filteredRules.isEmpty {
                        emptyStateView
                    } else {
                        LazyVStack(spacing: 8) {
                            ForEach(filteredRules) { rule in
                                ruleCard(rule: rule)
                            }
                        }
                    }
                }
                .padding(24)
            }
        }
        .background(Theme.bgDeep)
        .sheet(isPresented: $isShowingEditor) {
            RuleEditorSheet(
                rule: $editingRule,
                isPresented: $isShowingEditor,
                onSaved: {
                    loadRules()
                },
                onDeleted: {
                    loadRules()
                }
            )
        }
        .onAppear {
            loadRules()
        }
        .onReceive(NotificationCenter.default.publisher(for: DatabaseManager.didChangeNotification)) { _ in
            loadRules()
        }
    }
    
    // MARK: - Header Bar
    private var headerBar: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: "character.book.closed")
                        .foregroundColor(Theme.accentLight)
                    Text("Dictionary & Classification Rules")
                        .font(Theme.titleMedium)
                        .foregroundColor(Theme.textPrimary)
                }
                
                Text("\(rules.count) rules")
                    .font(Theme.caption)
                    .foregroundColor(Theme.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Theme.bgSubtle)
                    .cornerRadius(6)
                
                Spacer()
                
                // + Add Rule Button
                Button(action: {
                    editingRule = nil
                    isShowingEditor = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .bold))
                        Text("Add Rule")
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
            
            // Search & Filters Row
            HStack(spacing: 12) {
                // Search field
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textMuted)
                    
                    TextField("Search keywords or categories...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(Theme.body)
                        .foregroundColor(Theme.textPrimary)
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(Theme.textMuted)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Theme.bgDark)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1))
                .frame(maxWidth: 320)
                
                Spacer()
                
                // Filter Segment
                HStack(spacing: 4) {
                    ForEach(ProductivityFilter.allCases) { filter in
                        let isSelected = selectedFilter == filter
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                selectedFilter = filter
                            }
                        }) {
                            Text(filter.rawValue)
                                .font(Theme.caption)
                                .fontWeight(isSelected ? .semibold : .medium)
                                .foregroundColor(isSelected ? .white : Theme.textSecondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(isSelected ? Theme.accent : Theme.bgSubtle)
                                .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(Theme.bgDark)
        .overlay(
            Rectangle()
                .fill(Theme.border)
                .frame(height: 1),
            alignment: .bottom
        )
    }
    
    // MARK: - Rule Card
    private func ruleCard(rule: ClassificationRule) -> some View {
        let isHovered = hoveredRuleId == rule.id
        let prodColor = Color.forProductivity(rule.productivityType)
        
        return HStack(spacing: 16) {
            // Phrase Monospaced Pill
            HStack(spacing: 6) {
                Image(systemName: "quote.opening")
                    .font(.system(size: 9))
                    .foregroundColor(Theme.accentLight)
                Text(rule.phrase)
                    .font(Theme.monoBold)
                    .foregroundColor(Theme.textPrimary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Theme.bgDark)
            .cornerRadius(6)
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.border, lineWidth: 1))
            .frame(minWidth: 160, alignment: .leading)
            
            Image(systemName: "arrow.right")
                .font(.system(size: 11))
                .foregroundColor(Theme.textMuted)
            
            // Category Badge
            HStack(spacing: 6) {
                Image(systemName: "tag.fill")
                    .font(.system(size: 10))
                    .foregroundColor(Theme.accentLight)
                Text(rule.category)
                    .font(Theme.bodyMedium)
                    .foregroundColor(Theme.textPrimary)
            }
            
            Spacer()
            
            // Productivity Tag
            HStack(spacing: 5) {
                Circle()
                    .fill(prodColor)
                    .frame(width: 7, height: 7)
                Text(rule.productivityType.displayName)
                    .font(Theme.caption)
                    .fontWeight(.medium)
                    .foregroundColor(prodColor)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(prodColor.opacity(0.12))
            .cornerRadius(6)
            
            // Edit & Delete actions
            HStack(spacing: 6) {
                Button(action: {
                    editingRule = rule
                    isShowingEditor = true
                }) {
                    Image(systemName: "pencil")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                        .padding(5)
                        .background(Theme.bgSubtle)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Edit rule")
                
                Button(action: {
                    DatabaseManager.shared.deleteRule(id: rule.id)
                    loadRules()
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.wasteful.opacity(0.8))
                        .padding(5)
                        .background(Theme.wastefulBg)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Delete rule")
            }
            .opacity(isHovered ? 1.0 : 0.4)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(isHovered ? Theme.bgCardHover : Theme.bgCard)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isHovered ? Theme.borderHighlight : Theme.border, lineWidth: 1)
        )
        .onHover { hovering in
            hoveredRuleId = hovering ? rule.id : nil
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 14) {
            Image(systemName: "text.book.closed")
                .font(.system(size: 40))
                .foregroundColor(Theme.textMuted)
            
            Text(searchText.isEmpty ? "No Classification Rules Yet" : "No Rules Matching '\(searchText)'")
                .font(Theme.titleSmall)
                .foregroundColor(Theme.textPrimary)
            
            Text("Classification rules automatically match your typed or voice task descriptions to categories and productivity levels.")
                .font(Theme.caption)
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)
            
            Button(action: {
                SampleDataSeeder.seedDefaultRulesIfNeeded()
                loadRules()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                    Text("Load Starter Dictionary")
                }
                .font(Theme.caption)
                .fontWeight(.semibold)
                .foregroundColor(Theme.accentLight)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Theme.accent.opacity(0.15))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Theme.accent.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .padding(.top, 6)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .glassCard(cornerRadius: 14)
    }
    
    private func loadRules() {
        rules = DatabaseManager.shared.fetchAllRules()
    }
}
