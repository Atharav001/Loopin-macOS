import SwiftUI
import AppKit

public struct EntryBlockView: View {
    public let entry: TimesheetEntry
    public let hourHeight: CGFloat
    public let use24HourClock: Bool
    public var onSelect: ((TimesheetEntry) -> Void)?
    public var onResizeTop: ((TimesheetEntry, CGFloat) -> Void)?
    public var onResizeBottom: ((TimesheetEntry, CGFloat) -> Void)?
    public var onMove: ((TimesheetEntry, CGFloat) -> Void)?
    
    @State private var isHovered: Bool = false
    @State private var hoverZone: HoverZone = .none
    
    private enum HoverZone {
        case none
        case body
        case topEdge
        case bottomEdge
    }
    
    public init(
        entry: TimesheetEntry,
        hourHeight: CGFloat = 48,
        use24HourClock: Bool = false,
        onSelect: ((TimesheetEntry) -> Void)? = nil,
        onResizeTop: ((TimesheetEntry, CGFloat) -> Void)? = nil,
        onResizeBottom: ((TimesheetEntry, CGFloat) -> Void)? = nil,
        onMove: ((TimesheetEntry, CGFloat) -> Void)? = nil
    ) {
        self.entry = entry
        self.hourHeight = hourHeight
        self.use24HourClock = use24HourClock
        self.onSelect = onSelect
        self.onResizeTop = onResizeTop
        self.onResizeBottom = onResizeBottom
        self.onMove = onMove
    }
    
    private var isPlanned: Bool {
        entry.kind == EntryKind.planned.rawValue
    }
    
    private var blockColor: Color {
        if isPlanned {
            return Theme.planned
        } else {
            return Color.forProductivity(entry.productivityType)
        }
    }
    
    private var computedHeight: CGFloat {
        let durationHours = CGFloat(entry.duration) / 3600.0
        return max(24, durationHours * hourHeight)
    }
    
    private var formattedTimeRange: String {
        let f = DateFormatter()
        f.dateFormat = use24HourClock ? "HH:mm" : "h:mm a"
        return "\(f.string(from: entry.startAt)) – \(f.string(from: entry.endAt))"
    }
    
    public var body: some View {
        ZStack(alignment: .topLeading) {
            // Background & Border
            if isPlanned {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Theme.bgCard.opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(blockColor, style: StrokeStyle(lineWidth: 1.2, dash: [4, 3]))
                    )
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Theme.bgCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(blockColor.opacity(isHovered ? 0.85 : 0.35), lineWidth: 1)
                    )
            }
            
            // Left Clockify Color Strip
            HStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(blockColor)
                    .frame(width: 3.5)
                    .padding(.vertical, 3)
                    .padding(.leading, 3)
                
                // Content
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(entry.rawText.isEmpty ? "Untitled" : entry.rawText)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(Theme.textPrimary)
                            .lineLimit(computedHeight < 40 ? 1 : 2)
                        
                        Spacer(minLength: 0)
                        
                        Text(entry.formattedDuration)
                            .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                            .foregroundColor(blockColor)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(blockColor.opacity(0.16))
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                    }
                    
                    if computedHeight >= 42 {
                        HStack(spacing: 4) {
                            if let category = entry.category {
                                Text(category)
                                    .font(.system(size: 8.5, weight: .medium))
                                    .foregroundColor(Theme.textSecondary)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(Theme.bgDark)
                                    .clipShape(RoundedRectangle(cornerRadius: 3))
                            }
                            
                            Text(formattedTimeRange)
                                .font(.system(size: 8.5, design: .monospaced))
                                .foregroundColor(Theme.textMuted)
                        }
                    }
                }
                .padding(.horizontal, 5)
                .padding(.vertical, 3)
            }
            
            // Top Edge Resize Handle Overlay (6pt hit-zone)
            VStack {
                Rectangle()
                    .fill(Color.white.opacity(hoverZone == .topEdge ? 0.4 : 0.001))
                    .frame(height: 6)
                    .onHover { hovering in
                        if hovering {
                            hoverZone = .topEdge
                            NSCursor.resizeUpDown.set()
                        } else if hoverZone == .topEdge {
                            hoverZone = .none
                            NSCursor.arrow.set()
                        }
                    }
                
                Spacer()
                
                // Bottom Edge Resize Handle Overlay (6pt hit-zone)
                Rectangle()
                    .fill(Color.white.opacity(hoverZone == .bottomEdge ? 0.4 : 0.001))
                    .frame(height: 6)
                    .onHover { hovering in
                        if hovering {
                            hoverZone = .bottomEdge
                            NSCursor.resizeUpDown.set()
                        } else if hoverZone == .bottomEdge {
                            hoverZone = .none
                            NSCursor.arrow.set()
                        }
                    }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: computedHeight)
        .shadow(color: isHovered ? blockColor.opacity(0.4) : (AppState.shared.currentTheme.isDark ? Color.clear : Color.black.opacity(0.06)), radius: isHovered ? 4 : 2, y: 1)
        .onHover { hovering in
            isHovered = hovering
            if !hovering {
                hoverZone = .none
                NSCursor.arrow.set()
            }
        }
        .highPriorityGesture(
            TapGesture().onEnded {
                onSelect?(entry)
            }
        )
    }
}
