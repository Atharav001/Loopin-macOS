import SwiftUI
import AppKit

public struct EntryBlockView: View {
    public let entry: TimesheetEntry
    public let hourHeight: CGFloat
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
        onSelect: ((TimesheetEntry) -> Void)? = nil,
        onResizeTop: ((TimesheetEntry, CGFloat) -> Void)? = nil,
        onResizeBottom: ((TimesheetEntry, CGFloat) -> Void)? = nil,
        onMove: ((TimesheetEntry, CGFloat) -> Void)? = nil
    ) {
        self.entry = entry
        self.hourHeight = hourHeight
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
        return max(22, durationHours * hourHeight)
    }
    
    public var body: some View {
        ZStack(alignment: .topLeading) {
            // Background & Border
            if isPlanned {
                RoundedRectangle(cornerRadius: 6)
                    .fill(blockColor.opacity(isHovered ? 0.25 : 0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(blockColor, style: StrokeStyle(lineWidth: 1.5, dash: [4, 2]))
                    )
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(blockColor.opacity(isHovered ? 0.95 : 0.85))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(blockColor, lineWidth: 1)
                    )
            }
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(entry.rawText)
                        .font(Theme.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .lineLimit(computedHeight < 40 ? 1 : 2)
                    
                    Spacer(minLength: 0)
                    
                    Text(entry.formattedDuration)
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(Color.white.opacity(0.85))
                }
                
                if computedHeight >= 45 {
                    HStack(spacing: 4) {
                        if let category = entry.category {
                            Text(category)
                                .font(.system(size: 9, weight: .medium))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Color.black.opacity(0.2))
                                .cornerRadius(3)
                        }
                        
                        Text(entry.formattedTimeRange)
                            .font(.system(size: 9))
                            .foregroundColor(Color.white.opacity(0.7))
                    }
                    .foregroundColor(Color.white.opacity(0.9))
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            
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
        .shadow(color: isHovered ? blockColor.opacity(0.4) : Color.clear, radius: 4)
        .onHover { hovering in
            isHovered = hovering
            if !hovering {
                hoverZone = .none
                NSCursor.arrow.set()
            }
        }
        .onTapGesture {
            onSelect?(entry)
        }
    }
}
