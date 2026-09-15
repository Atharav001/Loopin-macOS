import SwiftUI

// MARK: - AppTheme Enum
public enum AppTheme: String, CaseIterable, Identifiable, Codable, Sendable {
    case clockifyDark = "Clockify Dark"
    case clockifyLight = "Clockify Light"
    case tickTickDark = "TickTick Dark"
    case tickTickLight = "TickTick Light"
    case systemDark = "Normal Dark (Google/Microsoft)"
    case standardLight = "Standard Light"
    case tocklogDark = "Tocklog Dark (Mobile Modern)"
    
    public var id: String { rawValue }
    
    public var isDark: Bool {
        switch self {
        case .clockifyDark, .tickTickDark, .systemDark, .tocklogDark:
            return true
        case .clockifyLight, .tickTickLight, .standardLight:
            return false
        }
    }
    
    public var iconName: String {
        switch self {
        case .clockifyDark: return "moon.stars.fill"
        case .clockifyLight: return "sun.max.fill"
        case .tickTickDark: return "checkmark.circle.fill"
        case .tickTickLight: return "checkmark.circle"
        case .systemDark: return "macwindow"
        case .standardLight: return "circle.lefthalf.filled"
        case .tocklogDark: return "flame.fill"
        }
    }
    
    public var description: String {
        switch self {
        case .clockifyDark: return "Deep midnight slate with signature Clockify cyan accent"
        case .clockifyLight: return "Clean soft grey canvas with crisp typography and cyan accents"
        case .tickTickDark: return "Warm slate dark mode with TickTick royal blue accents"
        case .tickTickLight: return "Clean modern white with TickTick blue buttons and badges"
        case .systemDark: return "Google & Microsoft neutral dark material surfaces"
        case .standardLight: return "Pure white Apple & Google minimal light aesthetic"
        case .tocklogDark: return "Mobile modern obsidian dark with signature warm amber & gold accents"
        }
    }
}

// MARK: - Dynamic Theme System
public enum Theme {
    @MainActor
    private static var activeTheme: AppTheme {
        AppState.shared.currentTheme
    }
    
    // Canvas Background
    @MainActor public static var bgDeep: Color {
        switch activeTheme {
        case .clockifyDark: return Color(red: 11/255, green: 15/255, blue: 25/255)       // #0B0F19
        case .clockifyLight: return Color(red: 244/255, green: 245/255, blue: 247/255)   // #F4F5F7
        case .tickTickDark: return Color(red: 30/255, green: 32/255, blue: 34/255)       // #1E2022
        case .tickTickLight: return Color(red: 246/255, green: 247/255, blue: 249/255)   // #F6F7F9
        case .systemDark: return Color(red: 18/255, green: 18/255, blue: 18/255)         // #121212
        case .standardLight: return Color(red: 255/255, green: 255/255, blue: 255/255)   // #FFFFFF
        case .tocklogDark: return Color(red: 20/255, green: 23/255, blue: 26/255)         // #14171A (Obsidian)
        }
    }
    
    // Sidebar & Navigation Headers
    @MainActor public static var bgDark: Color {
        switch activeTheme {
        case .clockifyDark: return Color(red: 17/255, green: 24/255, blue: 39/255)       // #111827
        case .clockifyLight: return Color(red: 255/255, green: 255/255, blue: 255/255)   // #FFFFFF
        case .tickTickDark: return Color(red: 37/255, green: 40/255, blue: 44/255)       // #25282C
        case .tickTickLight: return Color(red: 255/255, green: 255/255, blue: 255/255)   // #FFFFFF
        case .systemDark: return Color(red: 30/255, green: 30/255, blue: 30/255)         // #1E1E1E
        case .standardLight: return Color(red: 248/255, green: 249/255, blue: 250/255)   // #F8F9FA
        case .tocklogDark: return Color(red: 26/255, green: 29/255, blue: 33/255)         // #1A1D21
        }
    }
    
    // Cards & Block Containers
    @MainActor public static var bgCard: Color {
        switch activeTheme {
        case .clockifyDark: return Color(red: 24/255, green: 32/255, blue: 47/255)       // #18202F
        case .clockifyLight: return Color(red: 255/255, green: 255/255, blue: 255/255)   // #FFFFFF
        case .tickTickDark: return Color(red: 47/255, green: 51/255, blue: 56/255)       // #2F3338
        case .tickTickLight: return Color(red: 255/255, green: 255/255, blue: 255/255)   // #FFFFFF
        case .systemDark: return Color(red: 37/255, green: 37/255, blue: 37/255)         // #252525
        case .standardLight: return Color(red: 255/255, green: 255/255, blue: 255/255)   // #FFFFFF
        case .tocklogDark: return Color(red: 34/255, green: 38/255, blue: 43/255)         // #22262B
        }
    }
    
    // Card Hover Surface
    @MainActor public static var bgCardHover: Color {
        switch activeTheme {
        case .clockifyDark: return Color(red: 32/255, green: 43/255, blue: 63/255)
        case .clockifyLight: return Color(red: 241/255, green: 245/255, blue: 249/255)
        case .tickTickDark: return Color(red: 57/255, green: 62/255, blue: 68/255)
        case .tickTickLight: return Color(red: 237/255, green: 240/255, blue: 245/255)
        case .systemDark: return Color(red: 45/255, green: 45/255, blue: 45/255)
        case .standardLight: return Color(red: 241/255, green: 243/255, blue: 244/255)
        case .tocklogDark: return Color(red: 44/255, green: 49/255, blue: 55/255)         // #2C3137
        }
    }
    
    // Subtle hover surfaces
    @MainActor public static var bgSubtle: Color {
        if activeTheme.isDark {
            return Color(white: 1.0, opacity: 0.06)
        } else {
            return Color(white: 0.0, opacity: 0.05)
        }
    }
    
    // Primary Accent Color
    @MainActor public static var accent: Color {
        switch activeTheme {
        case .clockifyDark, .clockifyLight:
            return Color(red: 2/255, green: 136/255, blue: 235/255)      // #0288EB
        case .tickTickDark, .tickTickLight:
            return Color(red: 59/255, green: 104/255, blue: 255/255)     // #3B68FF
        case .systemDark, .standardLight:
            return Color(red: 26/255, green: 115/255, blue: 232/255)     // #1A73E8
        case .tocklogDark:
            return Color(red: 245/255, green: 158/255, blue: 11/255)     // #F59E0B (Signature Amber)
        }
    }
    
    @MainActor public static var accentLight: Color {
        switch activeTheme {
        case .clockifyDark: return Color(red: 56/255, green: 189/255, blue: 248/255)
        case .clockifyLight: return Color(red: 2/255, green: 136/255, blue: 235/255)
        case .tickTickDark: return Color(red: 96/255, green: 133/255, blue: 255/255)
        case .tickTickLight: return Color(red: 59/255, green: 104/255, blue: 255/255)
        case .systemDark: return Color(red: 138/255, green: 180/255, blue: 248/255)
        case .standardLight: return Color(red: 26/255, green: 115/255, blue: 232/255)
        case .tocklogDark: return Color(red: 251/255, green: 191/255, blue: 36/255)      // #FBBF24 (Gold)
        }
    }
    
    @MainActor public static var accentGlow: Color {
        accent.opacity(0.35)
    }
    
    // Harmonious Status Colors (Calibrated, Non-Neon)
    @MainActor public static var productive: Color {
        activeTheme.isDark
            ? Color(red: 52/255, green: 211/255, blue: 153/255)  // #34D399 (Emerald 400)
            : Color(red: 16/255, green: 149/255, blue: 106/255)  // #10956A (Emerald 600)
    }
    @MainActor public static var productiveBg: Color { productive.opacity(activeTheme.isDark ? 0.16 : 0.12) }
    
    @MainActor public static var neutral: Color {
        activeTheme.isDark
            ? Color(red: 56/255, green: 189/255, blue: 248/255)  // #38BDF8 (Sky 400)
            : Color(red: 2/255, green: 132/255, blue: 199/255)   // #0284C7 (Sky 600)
    }
    @MainActor public static var neutralBg: Color { neutral.opacity(activeTheme.isDark ? 0.16 : 0.12) }
    
    @MainActor public static var wasteful: Color {
        activeTheme.isDark
            ? Color(red: 251/255, green: 113/255, blue: 133/255) // #FB7185 (Rose 400)
            : Color(red: 225/255, green: 29/255, blue: 72/255)   // #E11D48 (Rose 600)
    }
    @MainActor public static var wastefulBg: Color { wasteful.opacity(activeTheme.isDark ? 0.16 : 0.12) }
    
    @MainActor public static var planned: Color {
        activeTheme.isDark
            ? Color(red: 167/255, green: 139/255, blue: 250/255) // #A78BFA (Violet 400)
            : Color(red: 124/255, green: 58/255, blue: 237/255)  // #7C3AED (Violet 600)
    }
    @MainActor public static var plannedBg: Color { planned.opacity(activeTheme.isDark ? 0.16 : 0.12) }
    
    @MainActor public static var skipped: Color {
        activeTheme.isDark
            ? Color(red: 148/255, green: 163/255, blue: 184/255) // #94A3B8
            : Color(red: 100/255, green: 116/255, blue: 139/255) // #64748B
    }
    @MainActor public static var skippedBg: Color { skipped.opacity(activeTheme.isDark ? 0.16 : 0.12) }
    
    @MainActor public static var nowLine: Color {
        Color(red: 239/255, green: 68/255, blue: 68/255)
    }
    
    // Typography Colors
    @MainActor public static var textPrimary: Color {
        if activeTheme.isDark {
            return Color(red: 248/255, green: 250/255, blue: 252/255) // #F8FAFC
        } else {
            return Color(red: 30/255, green: 41/255, blue: 59/255)    // #1E293B
        }
    }
    
    @MainActor public static var textSecondary: Color {
        if activeTheme.isDark {
            return Color(red: 148/255, green: 163/255, blue: 184/255) // #94A3B8
        } else {
            return Color(red: 71/255, green: 85/255, blue: 105/255)   // #475569
        }
    }
    
    @MainActor public static var textMuted: Color {
        if activeTheme.isDark {
            return Color(red: 100/255, green: 116/255, blue: 139/255) // #64748B
        } else {
            return Color(red: 148/255, green: 163/255, blue: 184/255) // #94A3B8
        }
    }
    
    // Borders
    @MainActor public static var border: Color {
        if activeTheme.isDark {
            return Color(white: 1.0, opacity: 0.08)
        } else {
            return Color(white: 0.0, opacity: 0.09)
        }
    }
    
    @MainActor public static var borderSubtle: Color {
        if activeTheme.isDark {
            return Color(white: 1.0, opacity: 0.04)
        } else {
            return Color(white: 0.0, opacity: 0.05)
        }
    }
    
    @MainActor public static var borderHighlight: Color {
        accent.opacity(0.4)
    }
    
    // Typography Presets
    public static let titleLarge = Font.system(size: 20, weight: .bold, design: .rounded)
    public static let titleMedium = Font.system(size: 15, weight: .semibold, design: .rounded)
    public static let titleSmall = Font.system(size: 13, weight: .semibold, design: .rounded)
    public static let body = Font.system(size: 12, weight: .regular, design: .default)
    public static let bodyMedium = Font.system(size: 12, weight: .medium, design: .default)
    public static let caption = Font.system(size: 10.5, weight: .medium, design: .default)
    public static let mono = Font.system(size: 11, weight: .regular, design: .monospaced)
    public static let monoBold = Font.system(size: 11, weight: .bold, design: .monospaced)
}

// MARK: - Visual Modifiers
public struct GlassCardModifier: ViewModifier {
    @ObservedObject var appState: AppState = .shared
    var cornerRadius: CGFloat = 12
    var strokeColor: Color? = nil
    
    public func body(content: Content) -> some View {
        let isDark = appState.currentTheme.isDark
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(isDark ? Theme.bgCard : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(strokeColor ?? (isDark ? Theme.border : Color.black.opacity(0.08)), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(isDark ? 0.25 : 0.05), radius: isDark ? 6 : 8, x: 0, y: isDark ? 2 : 2)
    }
}

public extension View {
    func glassCard(cornerRadius: CGFloat = 12, strokeColor: Color? = nil) -> some View {
        self.modifier(GlassCardModifier(cornerRadius: cornerRadius, strokeColor: strokeColor))
    }
}
