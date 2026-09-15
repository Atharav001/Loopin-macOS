import SwiftUI

public struct SidebarView: View {
    @ObservedObject var appState: AppState = .shared
    @Binding var isPinnedOnTop: Bool
    var onTogglePin: (() -> Void)?
    var onNewEntry: (() -> Void)?
    
    @State private var hoveredTab: NavigationTab?
    
    public init(
        isPinnedOnTop: Binding<Bool>,
        onTogglePin: (() -> Void)? = nil,
        onNewEntry: (() -> Void)? = nil
    ) {
        self._isPinnedOnTop = isPinnedOnTop
        self.onTogglePin = onTogglePin
        self.onNewEntry = onNewEntry
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 1. Top Traffic Light Header Area with Window Dragging
            ZStack(alignment: .leading) {
                WindowDragArea()
                
                HStack(spacing: 8) {
                    Image(systemName: "timer.circle.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Theme.accent)
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Logtrackin")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.textPrimary)
                            .tracking(0.3)
                        
                        Text("Workspace")
                            .font(.system(size: 9.5, weight: .medium))
                            .foregroundColor(Theme.textMuted)
                    }
                }
                .padding(.leading, 78) // Generous offset for macOS traffic lights
            }
            .frame(height: 52)
            
            // 2. Quick "+ New Entry" Action Button
            Button(action: {
                onNewEntry?()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                    Text("New Entry")
                        .font(.system(size: 12, weight: .semibold))
                    Spacer()
                    Text("⌘N")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(Color.white.opacity(0.7))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Theme.accent)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(color: Theme.accent.opacity(0.3), radius: 4, y: 1)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 14)
            .padding(.top, 4)
            .padding(.bottom, 16)
            
            // 3. Navigation Items
            VStack(alignment: .leading, spacing: 3) {
                Text("MAIN VIEWS")
                    .font(.system(size: 9.5, weight: .bold))
                    .foregroundColor(Theme.textMuted)
                    .tracking(0.8)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 4)
                
                sidebarButton(for: .weekCalendar)
                sidebarButton(for: .rails)
                sidebarButton(for: .analytics)
                sidebarButton(for: .dictionary)
                sidebarButton(for: .focusPrompts)
                
                Divider()
                    .background(Theme.border)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                
                Text("PREFERENCES")
                    .font(.system(size: 9.5, weight: .bold))
                    .foregroundColor(Theme.textMuted)
                    .tracking(0.8)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 4)
                
                sidebarButton(for: .settings)
            }
            
            Spacer()
            
            // 4. Bottom Footer: Live Interval Status & Window Pin
            VStack(spacing: 10) {
                // Live Interval Card
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Theme.accent)
                            .frame(width: 7, height: 7)
                        Text(appState.selectedIntervalMinutes == 60 ? "1-Hour Interval" : "\(appState.selectedIntervalMinutes)m Interval")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Theme.textSecondary)
                        Spacer()
                        Text(appState.formattedCountdown)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(Theme.accentLight)
                    }
                    
                    Button(action: {
                        appState.showFloatingLoggingPanel = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 10))
                            Text("Log Interval Now")
                                .font(.system(size: 10.5, weight: .medium))
                        }
                        .foregroundColor(Theme.accentLight)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4.5)
                        .background(Theme.accent.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                    }
                    .buttonStyle(.plain)
                }
                .padding(10)
                .background(Theme.bgSubtle)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Theme.border, lineWidth: 1)
                )
                
                // Pin on top toggle
                HStack {
                    Button(action: {
                        onTogglePin?()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: isPinnedOnTop ? "pin.fill" : "pin")
                                .font(.system(size: 11))
                                .foregroundColor(isPinnedOnTop ? Theme.accentLight : Theme.textSecondary)
                            Text(isPinnedOnTop ? "Pinned on Top" : "Pin on Top")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(isPinnedOnTop ? Theme.textPrimary : Theme.textSecondary)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    // Theme Quick Indicator
                    Text(appState.currentTheme.isDark ? "DARK" : "LIGHT")
                        .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.textMuted)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Theme.bgSubtle)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                }
                .padding(.horizontal, 4)
            }
            .padding(14)
        }
        .frame(width: 220)
        .background(Theme.bgDark)
        .overlay(
            Rectangle()
                .fill(Theme.border)
                .frame(width: 1),
            alignment: .trailing
        )
    }
    
    private func sidebarButton(for tab: NavigationTab) -> some View {
        let isSelected = appState.selectedTab == tab
        let isHovered = hoveredTab == tab
        
        return Button(action: {
            withAnimation(.easeInOut(duration: 0.15)) {
                appState.selectedTab = tab
            }
        }) {
            HStack(spacing: 9) {
                Image(systemName: tab.iconName)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? Theme.accentLight : (isHovered ? Theme.textPrimary : Theme.textSecondary))
                    .frame(width: 18)
                
                Text(tab.rawValue)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? Theme.textPrimary : (isHovered ? Theme.textPrimary : Theme.textSecondary))
                
                Spacer()
                
                if isSelected {
                    Circle()
                        .fill(Theme.accent)
                        .frame(width: 5, height: 5)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 7)
                            .fill(Theme.accent.opacity(0.14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 7)
                                    .stroke(Theme.accent.opacity(0.3), lineWidth: 1)
                            )
                    } else if isHovered {
                        RoundedRectangle(cornerRadius: 7)
                            .fill(Theme.bgSubtle)
                    }
                }
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 10)
        .onHover { hovering in
            hoveredTab = hovering ? tab : nil
        }
    }
}
