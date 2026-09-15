import SwiftUI

public struct TabBarView: View {
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
        ZStack {
            // Drag area for native window movement
            WindowDragArea()
            
            HStack(spacing: 16) {
                // Left App Identity (offset for traffic lights)
                HStack(spacing: 8) {
                    Image(systemName: "timer.circle.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Theme.accent)
                    
                    Text("Logtrackin")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.textPrimary)
                        .tracking(0.3)
                }
                .padding(.leading, 78) // Space for native traffic lights
                
                Spacer()
                
                // 5 Sleek Tabs
                HStack(spacing: 2) {
                    ForEach(NavigationTab.allCases) { tab in
                        tabButton(tab)
                    }
                }
                .padding(3)
                .background(Theme.bgDark.opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Theme.border, lineWidth: 1)
                )
                
                Spacer()
                
                // Right Action Controls
                HStack(spacing: 8) {
                    // Quick + Entry Button
                    Button(action: {
                        onNewEntry?()
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "plus")
                                .font(.system(size: 10, weight: .bold))
                            Text("New Entry")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 5.5)
                        .background(Theme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .shadow(color: Theme.accent.opacity(0.3), radius: 4, y: 1)
                    }
                    .buttonStyle(.plain)
                    .help("Add new entry (Cmd+N)")
                    
                    // Pin on top toggle
                    Button(action: {
                        onTogglePin?()
                    }) {
                        Image(systemName: isPinnedOnTop ? "pin.fill" : "pin")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(isPinnedOnTop ? Theme.accentLight : Theme.textSecondary)
                            .frame(width: 28, height: 28)
                            .background(isPinnedOnTop ? Theme.accent.opacity(0.18) : Theme.bgSubtle)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(isPinnedOnTop ? Theme.accent.opacity(0.8) : Theme.border, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .help(isPinnedOnTop ? "Unpin Window" : "Pin Window on Top")
                }
                .padding(.trailing, 16)
            }
        }
        .frame(height: 48)
        .background(Theme.bgDark)
        .overlay(
            Rectangle()
                .fill(Theme.border)
                .frame(height: 1),
            alignment: .bottom
        )
    }
    
    private func tabButton(_ tab: NavigationTab) -> some View {
        let isSelected = appState.selectedTab == tab
        let isHovered = hoveredTab == tab
        
        return Button(action: {
            withAnimation(.easeInOut(duration: 0.15)) {
                appState.selectedTab = tab
            }
        }) {
            HStack(spacing: 5) {
                Image(systemName: tab.iconName)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                Text(tab.rawValue)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .medium))
            }
            .foregroundColor(isSelected ? .white : (isHovered ? Theme.textPrimary : Theme.textSecondary))
            .padding(.horizontal, 11)
            .padding(.vertical, 5)
            .background(
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Theme.accent)
                    } else if isHovered {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Theme.bgSubtle)
                    }
                }
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            hoveredTab = hovering ? tab : nil
        }
        .help("Switch to \(tab.rawValue) (Cmd+\(tab.shortcutNumber))")
    }
}
