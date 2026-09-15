import SwiftUI

// MARK: - Loopin Design System & Theme Tokens
public enum Theme {
    // Backgrounds
    public static let bgDeep = Color(red: 13/255, green: 14/255, blue: 18/255)
    public static let bgDark = Color(red: 19/255, green: 21/255, blue: 27/255)
    public static let bgCard = Color(red: 27/255, green: 30/255, blue: 39/255)
    public static let bgCardHover = Color(red: 35/255, green: 39/255, blue: 50/255)
    public static let bgSubtle = Color(red: 255/255, green: 255/255, blue: 255/255, opacity: 0.05)
    public static let bgGlass = Color(red: 20/255, green: 23/255, blue: 31/255, opacity: 0.75)
    
    // Accents & Productivity Colors
    public static let accent = Color(red: 99/255, green: 102/255, blue: 241/255) // Indigo
    public static let accentLight = Color(red: 129/255, green: 140/255, blue: 248/255)
    public static let accentGlow = Color(red: 99/255, green: 102/255, blue: 241/255, opacity: 0.4)
    
    // Productivity Categorization Colors
    public static let productive = Color(red: 34/255, green: 197/255, blue: 94/255) // Emerald green
    public static let productiveBg = Color(red: 34/255, green: 197/255, blue: 94/255, opacity: 0.15)
    
    public static let neutral = Color(red: 59/255, green: 130/255, blue: 246/255) // Sky blue
    public static let neutralBg = Color(red: 59/255, green: 130/255, blue: 246/255, opacity: 0.15)
    
    public static let wasteful = Color(red: 239/255, green: 68/255, blue: 68/255) // Coral red
    public static let wastefulBg = Color(red: 239/255, green: 68/255, blue: 68/255, opacity: 0.15)
    
    public static let planned = Color(red: 168/255, green: 85/255, blue: 247/255) // Purple
    public static let plannedBg = Color(red: 168/255, green: 85/255, blue: 247/255, opacity: 0.15)
    
    public static let skipped = Color(red: 148/255, green: 163/255, blue: 184/255) // Slate gray
    public static let skippedBg = Color(red: 148/255, green: 163/255, blue: 184/255, opacity: 0.15)
    
    public static let nowLine = Color(red: 239/255, green: 68/255, blue: 68/255) // Live red time indicator
    
    // Text colors
    public static let textPrimary = Color.white
    public static let textSecondary = Color(red: 156/255, green: 163/255, blue: 175/255)
    public static let textMuted = Color(red: 107/255, green: 114/255, blue: 128/255)
    
    // Border lines
    public static let border = Color(red: 255/255, green: 255/255, blue: 255/255, opacity: 0.08)
    public static let borderSubtle = Color(red: 255/255, green: 255/255, blue: 255/255, opacity: 0.04)
    public static let borderHighlight = Color(red: 255/255, green: 255/255, blue: 255/255, opacity: 0.15)
    
    // Fonts
    public static let titleLarge = Font.system(size: 22, weight: .bold, design: .rounded)
    public static let titleMedium = Font.system(size: 16, weight: .semibold, design: .rounded)
    public static let titleSmall = Font.system(size: 14, weight: .semibold, design: .rounded)
    public static let body = Font.system(size: 13, weight: .regular, design: .default)
    public static let bodyMedium = Font.system(size: 13, weight: .medium, design: .default)
    public static let caption = Font.system(size: 11, weight: .medium, design: .default)
    public static let mono = Font.system(size: 12, weight: .regular, design: .monospaced)
    public static let monoBold = Font.system(size: 12, weight: .bold, design: .monospaced)
}

// MARK: - Visual Modifiers
public struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 12
    var strokeColor: Color = Theme.border
    
    public func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Theme.bgCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(strokeColor, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
}

public extension View {
    func glassCard(cornerRadius: CGFloat = 12, strokeColor: Color = Theme.border) -> some View {
        self.modifier(GlassCardModifier(cornerRadius: cornerRadius, strokeColor: strokeColor))
    }
}
