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
    
    private var sidebarWidth: CGFloat {
        appState.isSidebarCollapsed ? 60 : 230
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if appState.isSidebarCollapsed {
                collapsedSidebarBody
            } else {
                expandedSidebarBody
            }
        }
        .frame(width: sidebarWidth)
        .background(Theme.bgDark)
        .overlay(
            Rectangle()
                .fill(Theme.border)
                .frame(width: 1),
            alignment: .trailing
        )
        .animation(.spring(response: 0.28, dampingFraction: 0.85), value: appState.isSidebarCollapsed)
    }
    
    // MARK: - Expanded Sidebar Body
    private var expandedSidebarBody: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 1. Top Header Area (Traffic light offset + Logo + Full Name + Collapse Button)
            ZStack(alignment: .leading) {
                WindowDragArea()
                
                HStack(spacing: 8) {
                    Image(systemName: "timer")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Theme.accentLight)
                        .frame(width: 20)
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Logtrackin")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.textPrimary)
                            .tracking(0.3)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                        
                        Text("Workspace")
                            .font(.system(size: 9.5, weight: .medium))
                            .foregroundColor(Theme.textMuted)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    
                    Spacer(minLength: 8)
                    
                    // Collapse button at top
                    Button(action: {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                            appState.isSidebarCollapsed = true
                        }
                    }) {
                        Image(systemName: "sidebar.leading")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Theme.textSecondary)
                            .frame(width: 24, height: 24)
                            .background(Theme.bgSubtle)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Theme.border, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .help("Collapse Sidebar")
                }
                .padding(.leading, 70) // Exact clearance for macOS traffic lights
                .padding(.trailing, 10)
            }
            .frame(height: 52)
            
            // Workspace / Profile Quick Pill
            Button(action: {
                appState.selectedTab = .account
            }) {
                HStack(spacing: 7) {
                    Circle()
                        .fill(appState.isSignedInWithGoogle ? Theme.productive : Theme.accent)
                        .frame(width: 7, height: 7)
                    
                    Text(appState.isSignedInWithGoogle ? appState.googleUserName : "Personal Workspace")
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)
                        .lineLimit(1)
                    
                    Spacer(minLength: 2)
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(Theme.textMuted)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Theme.bgSubtle)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Theme.border, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 14)
            .padding(.bottom, 10)
            
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
            
            // 3. Navigation Items (Scrollable)
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("MAIN VIEWS")
                        .font(.system(size: 9.5, weight: .bold))
                        .foregroundColor(Theme.textMuted)
                        .tracking(0.8)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 4)
                    
                    sidebarButton(for: .calendar)
                    sidebarButton(for: .weekCalendar)
                    sidebarButton(for: .rails)
                    sidebarButton(for: .analytics)
                    sidebarButton(for: .dictionary)
                    sidebarButton(for: .focusPrompts)
                    sidebarButton(for: .account)
                    
                    Divider()
                        .background(Theme.border)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                    
                    Text("PREFERENCES")
                        .font(.system(size: 9.5, weight: .bold))
                        .foregroundColor(Theme.textMuted)
                        .tracking(0.8)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 4)
                    
                    sidebarButton(for: .settings)
                }
            }
            
            Spacer(minLength: 4)
            
            // 4. Bottom Footer: Live Interval Status, Dropdown Theme Switcher & Window Pin
            VStack(spacing: 8) {
                // Quick Theme Dropdown Switcher
                ThemeDropdownPicker(compact: true)
                
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
                }
                .padding(.horizontal, 4)
                .padding(.top, 2)
            }
            .padding(12)
        }
    }
    
    // MARK: - Collapsed Sidebar Body (Icon Rail only)
    private var collapsedSidebarBody: some View {
        VStack(spacing: 12) {
            // Top Window drag + Expand Button
            ZStack(alignment: .center) {
                WindowDragArea()
                
                Button(action: {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                        appState.isSidebarCollapsed = false
                    }
                }) {
                    Image(systemName: "sidebar.leading")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)
                        .frame(width: 34, height: 34)
                        .background(Theme.bgSubtle)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Theme.border, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .help("Expand Sidebar")
            }
            .frame(height: 52)
            .padding(.top, 4)
            
            // App Logo Icon (Minimal Timer matching menu bar and dock icon)
            Image(systemName: "timer")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Theme.accentLight)
                .padding(.bottom, 2)
            
            // Quick "+ New Entry" Icon Button
            Button(action: {
                onNewEntry?()
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Theme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(color: Theme.accent.opacity(0.3), radius: 3, y: 1)
            }
            .buttonStyle(.plain)
            .help("New Entry (⌘N)")
            .padding(.bottom, 6)
            
            Divider()
                .background(Theme.border)
                .padding(.horizontal, 10)
            
            // Scrollable Icon Rail for Navigation Tabs
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 8) {
                    collapsedSidebarIconButton(for: .calendar)
                    collapsedSidebarIconButton(for: .weekCalendar)
                    collapsedSidebarIconButton(for: .rails)
                    collapsedSidebarIconButton(for: .analytics)
                    collapsedSidebarIconButton(for: .dictionary)
                    collapsedSidebarIconButton(for: .focusPrompts)
                    collapsedSidebarIconButton(for: .account)
                }
                .padding(.vertical, 2)
            }
            
            Spacer(minLength: 4)
            
            Divider()
                .background(Theme.border)
                .padding(.horizontal, 10)
            
            // Collapsed Settings & Pin Buttons
            collapsedSidebarIconButton(for: .settings)
            
            Button(action: {
                onTogglePin?()
            }) {
                Image(systemName: isPinnedOnTop ? "pin.fill" : "pin")
                    .font(.system(size: 13))
                    .foregroundColor(isPinnedOnTop ? Theme.accentLight : Theme.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(isPinnedOnTop ? Theme.accent.opacity(0.15) : Theme.bgSubtle)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isPinnedOnTop ? Theme.accent.opacity(0.35) : Theme.border, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .help(isPinnedOnTop ? "Pinned on Top (Click to unpin)" : "Pin Window on Top")
            .padding(.bottom, 12)
        }
        .frame(width: 60)
    }
    
    // MARK: - Expanded Navigation Button
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
    
    // MARK: - Collapsed Icon Button
    private func collapsedSidebarIconButton(for tab: NavigationTab) -> some View {
        let isSelected = appState.selectedTab == tab
        let isHovered = hoveredTab == tab
        
        return Button(action: {
            withAnimation(.easeInOut(duration: 0.15)) {
                appState.selectedTab = tab
            }
        }) {
            Image(systemName: tab.iconName)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? Theme.accentLight : (isHovered ? Theme.textPrimary : Theme.textSecondary))
                .frame(width: 36, height: 36)
                .background(
                    ZStack {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Theme.accent.opacity(0.18))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Theme.accent.opacity(0.4), lineWidth: 1)
                                )
                        } else if isHovered {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Theme.bgSubtle)
                        }
                    }
                )
        }
        .buttonStyle(.plain)
        .help(tab.rawValue)
        .onHover { hovering in
            hoveredTab = hovering ? tab : nil
        }
    }
}
