import SwiftUI

// MARK: - RippleConfirmModifier
public struct RippleConfirmModifier: ViewModifier {
    public var trigger: Bool
    public var rippleColor: Color
    
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.0
    
    public init(trigger: Bool, rippleColor: Color = Theme.productive) {
        self.trigger = trigger
        self.rippleColor = rippleColor
    }
    
    public func body(content: Content) -> some View {
        content
            .overlay(
                Circle()
                    .stroke(rippleColor, lineWidth: 2)
                    .scaleEffect(scale)
                    .opacity(opacity)
            )
            .onChange(of: trigger) { _, newValue in
                guard newValue, !reduceMotion else { return }
                scale = 0.8
                opacity = 0.9
                withAnimation(.easeOut(duration: 0.5)) {
                    scale = 2.2
                    opacity = 0.0
                }
            }
    }
}

public extension View {
    func rippleConfirm(trigger: Bool, rippleColor: Color = Theme.productive) -> some View {
        self.modifier(RippleConfirmModifier(trigger: trigger, rippleColor: rippleColor))
    }
}
