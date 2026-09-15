import SwiftUI

public struct TodayBlocksListView: View {
    public var entries: [TimesheetEntry]
    public var onEdit: ((TimesheetEntry) -> Void)?
    public var onDelete: ((TimesheetEntry) -> Void)?
    public var onAddSample: (() -> Void)?
    
    @State private var hoveredId: String?
    
    public init(
        entries: [TimesheetEntry],
        onEdit: ((TimesheetEntry) -> Void)? = nil,
        onDelete: ((TimesheetEntry) -> Void)? = nil,
        onAddSample: (() -> Void)? = nil
    ) {
        self.entries = entries
        self.onEdit = onEdit
        self.onDelete = onDelete
        self.onAddSample = onAddSample
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "list.bullet.rectangle.portrait")
                        .foregroundColor(Theme.accentLight)
                    Text("Today's Blocks Breakdown")
                        .font(Theme.titleSmall)
                        .foregroundColor(Theme.textPrimary)
                }
                
                Spacer()
                
                Text("\(entries.count) blocks")
                    .font(Theme.caption)
                    .foregroundColor(Theme.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Theme.bgSubtle)
                    .cornerRadius(6)
            }
            
            if entries.isEmpty {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "clock.badge.questionmark")
                        .font(.system(size: 36))
                        .foregroundColor(Theme.textMuted)
                    
                    Text("No blocks recorded for today yet")
                        .font(Theme.bodyMedium)
                        .foregroundColor(Theme.textSecondary)
                    
                    Text("Type a quick plan above or click below to seed starter blocks.")
                        .font(Theme.caption)
                        .foregroundColor(Theme.textMuted)
                    
                    Button(action: {
                        onAddSample?()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                            Text("Seed Sample Day")
                        }
                        .font(Theme.caption)
                        .foregroundColor(Theme.accentLight)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Theme.accent.opacity(0.15))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Theme.accent.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(Theme.bgDark.opacity(0.4))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Theme.borderSubtle, lineWidth: 1)
                )
            } else {
                // List of blocks
                VStack(spacing: 8) {
                    ForEach(entries) { entry in
                        entryCard(entry: entry)
                    }
                }
            }
        }
        .padding(16)
        .glassCard(cornerRadius: 14)
    }
    
    private func entryCard(entry: TimesheetEntry) -> some View {
        let isHovered = hoveredId == entry.id
        let isPlanned = entry.kind == EntryKind.planned.rawValue
        let color = isPlanned ? Theme.planned : Color.forProductivity(entry.productivityType)
        
        return HStack(spacing: 12) {
            // Color stripe
            RoundedRectangle(cornerRadius: 3)
                .fill(color)
                .frame(width: 4, height: 38)
            
            // Time range & Duration
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.formattedTimeRange)
                    .font(Theme.caption)
                    .foregroundColor(Theme.textSecondary)
                
                Text(entry.formattedDuration)
                    .font(Theme.monoBold)
                    .foregroundColor(Theme.textPrimary)
            }
            .frame(width: 110, alignment: .leading)
            
            // Kind Badge
            Text(isPlanned ? "PLANNED" : "LOGGED")
                .font(.system(size: 9, weight: .bold))
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(isPlanned ? Theme.plannedBg : Theme.neutralBg)
                .foregroundColor(isPlanned ? Theme.planned : Theme.neutral)
                .cornerRadius(4)
            
            // Raw text / Title
            Text(entry.rawText)
                .font(Theme.bodyMedium)
                .foregroundColor(Theme.textPrimary)
                .lineLimit(1)
            
            Spacer()
            
            // Category Badge
            if let category = entry.category {
                Text(category)
                    .font(Theme.caption)
                    .foregroundColor(Theme.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Theme.bgSubtle)
                    .cornerRadius(6)
            }
            
            // Productivity Badge
            if let prod = entry.productivityType {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.forProductivity(prod))
                        .frame(width: 6, height: 6)
                    Text(prod.displayName)
                        .font(Theme.caption)
                        .foregroundColor(Color.forProductivity(prod))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.forProductivity(prod).opacity(0.12))
                .cornerRadius(6)
            }
            
            // Input Method Icon
            Image(systemName: inputMethodIcon(entry.inputMethod))
                .font(.system(size: 11))
                .foregroundColor(Theme.textMuted)
                .help("Input: \(entry.inputMethod.capitalized)")
            
            // Edit & Delete actions
            HStack(spacing: 6) {
                Button(action: {
                    onEdit?(entry)
                }) {
                    Image(systemName: "pencil")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                        .padding(5)
                        .background(Theme.bgSubtle)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Edit entry")
                
                Button(action: {
                    onDelete?(entry)
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.wasteful.opacity(0.8))
                        .padding(5)
                        .background(Theme.wastefulBg)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Delete entry")
            }
            .opacity(isHovered ? 1.0 : 0.4)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isHovered ? Theme.bgCardHover : (AppState.shared.currentTheme.isDark ? Theme.bgDark.opacity(0.5) : Color(red: 247/255, green: 248/255, blue: 250/255)))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isHovered ? Theme.borderHighlight : Theme.borderSubtle, lineWidth: 1)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                hoveredId = hovering ? entry.id : nil
            }
        }
    }
    
    private func inputMethodIcon(_ method: String) -> String {
        switch method.lowercased() {
        case "voice": return "mic.fill"
        case "skipped": return "forward.fill"
        default: return "keyboard"
        }
    }
}
