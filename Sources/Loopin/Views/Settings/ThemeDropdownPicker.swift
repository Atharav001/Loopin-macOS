import SwiftUI

public struct ThemeDropdownPicker: View {
    @ObservedObject var appState: AppState = .shared
    public var compact: Bool = false
    
    public init(compact: Bool = false) {
        self.compact = compact
    }
    
    public var body: some View {
        Menu {
            ForEach(AppTheme.allCases) { theme in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        appState.currentTheme = theme
                    }
                }) {
                    HStack {
                        Label(theme.rawValue, systemImage: theme.iconName)
                        if appState.currentTheme == theme {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 8) {
                // Theme Color Swatch Pill
                HStack(spacing: 3) {
                    Circle()
                        .fill(themeAccent(for: appState.currentTheme))
                        .frame(width: 8, height: 8)
                    Circle()
                        .fill(themeSecondary(for: appState.currentTheme))
                        .frame(width: 8, height: 8)
                }
                
                Image(systemName: appState.currentTheme.iconName)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Theme.accentLight)
                
                Text(appState.currentTheme.rawValue)
                    .font(.system(size: compact ? 11 : 12.5, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                
                Spacer(minLength: 4)
                
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Theme.textMuted)
            }
            .padding(.horizontal, compact ? 10 : 14)
            .padding(.vertical, compact ? 6 : 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(appState.currentTheme.isDark ? Theme.bgCardHover : Color(white: 0.95))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Theme.border, lineWidth: 1)
            )
        }
        .menuStyle(.borderlessButton)
        .fixedSize(horizontal: false, vertical: true)
    }
    
    private func themeAccent(for theme: AppTheme) -> Color {
        switch theme {
        case .clockifyDark, .clockifyLight: return Color(red: 2/255, green: 136/255, blue: 235/255)
        case .tickTickDark, .tickTickLight: return Color(red: 59/255, green: 104/255, blue: 255/255)
        case .systemDark, .standardLight: return Color(red: 26/255, green: 115/255, blue: 232/255)
        case .tocklogDark: return Color(red: 245/255, green: 158/255, blue: 11/255)
        }
    }
    
    private func themeSecondary(for theme: AppTheme) -> Color {
        switch theme {
        case .clockifyDark: return Color(red: 56/255, green: 189/255, blue: 248/255)
        case .clockifyLight: return Color(red: 244/255, green: 245/255, blue: 247/255)
        case .tickTickDark: return Color(red: 96/255, green: 133/255, blue: 255/255)
        case .tickTickLight: return Color(red: 237/255, green: 240/255, blue: 245/255)
        case .systemDark: return Color(red: 138/255, green: 180/255, blue: 248/255)
        case .standardLight: return Color(red: 255/255, green: 255/255, blue: 255/255)
        case .tocklogDark: return Color(red: 251/255, green: 191/255, blue: 36/255)
        }
    }
}
