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
        HStack(spacing: 16) {
            // Left App Identity (offset for traffic lights)
            HStack(spacing: 8) {
                Image(systemName: "timer.circle.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Theme.accentLight)
                
                Text("Loopin")
                    .font(Theme.titleSmall)
                    .foregroundColor(Theme.textPrimary)
            }
            .padding(.leading, 80) // Leave space for native system traffic lights
            
            Spacer()
            
            // 5 Tabs
            HStack(spacing: 4) {
                ForEach(NavigationTab.allCases) { tab in
                    tabButton(tab)
                }
            }
            .padding(4)
            .background(Theme.bgDark.opacity(0.8))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Theme.border, lineWidth: 1)
            )
            
            Spacer()
            
            // Right Action Controls
            HStack(spacing: 10) {
                // Quick + Entry Button
                Button(action: {
                    onNewEntry?()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .bold))
                        Text("Add")
                            .font(Theme.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Theme.accent)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .help("Add new entry")
                
                // Pin on top toggle
                Button(action: {
                    onTogglePin?()
                }) {
                    Image(systemName: isPinnedOnTop ? "pin.fill" : "pin")
                        .font(.system(size: 12))
                        .foregroundColor(isPinnedOnTop ? Theme.accentLight : Theme.textSecondary)
                        .padding(6)
                        .background(isPinnedOnTop ? Theme.accent.opacity(0.2) : Theme.bgSubtle)
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(isPinnedOnTop ? Theme.accent : Theme.border, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .help(isPinnedOnTop ? "Unpin Window" : "Pin Window on Top")
            }
            .padding(.trailing, 16)
        }
        .frame(height: 52)
        .background(Theme.bgDark.opacity(0.95))
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
            HStack(spacing: 6) {
                Image(systemName: tab.iconName)
                    .font(.system(size: 12))
                Text(tab.rawValue)
                    .font(Theme.caption)
                    .fontWeight(isSelected ? .semibold : .medium)
            }
            .foregroundColor(isSelected ? .white : (isHovered ? Theme.textPrimary : Theme.textSecondary))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 7)
                            .fill(Theme.accent)
                            .shadow(color: Theme.accentGlow, radius: 4)
                    } else if isHovered {
                        RoundedRectangle(cornerRadius: 7)
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
