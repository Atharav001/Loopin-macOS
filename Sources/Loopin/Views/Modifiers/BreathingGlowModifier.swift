import SwiftUI

// MARK: - BreathingGlowModifier
public struct BreathingGlowModifier: ViewModifier {
    public var active: Bool
    public var glowColor: Color
    public var cornerRadius: CGFloat
    
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var isPulsing: Bool = false
    
    public init(active: Bool = true, glowColor: Color = Theme.accent, cornerRadius: CGFloat = 14) {
        self.active = active
        self.glowColor = glowColor
        self.cornerRadius = cornerRadius
    }
    
    public func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(glowColor.opacity(active ? (isPulsing ? 0.8 : 0.25) : 0), lineWidth: active ? (isPulsing ? 2.0 : 1.0) : 0)
                    .shadow(color: glowColor.opacity(active ? (isPulsing ? 0.6 : 0.15) : 0), radius: active ? (isPulsing ? 10 : 4) : 0)
            )
            .onAppear {
                guard active, !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
            .onChange(of: active) { _, newValue in
                if newValue && !reduceMotion {
                    withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                        isPulsing = true
                    }
                } else {
                    isPulsing = false
                }
            }
    }
}

public extension View {
    func breathingGlow(active: Bool = true, glowColor: Color = Theme.accent, cornerRadius: CGFloat = 14) -> some View {
        self.modifier(BreathingGlowModifier(active: active, glowColor: glowColor, cornerRadius: cornerRadius))
    }
}
