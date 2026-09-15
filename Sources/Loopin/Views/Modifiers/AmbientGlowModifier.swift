import SwiftUI

// MARK: - AmbientCelebrationGlowModifier
public struct AmbientCelebrationGlowModifier: ViewModifier {
    @Binding var isTriggered: Bool
    var glowColor: Color
    
    @State private var glowOpacity: Double = 0.0
    @State private var glowScale: CGFloat = 1.0
    
    public init(isTriggered: Binding<Bool>, glowColor: Color = Theme.accent) {
        self._isTriggered = isTriggered
        self.glowColor = glowColor
    }
    
    public func body(content: Content) -> some View {
        ZStack {
            content
            
            // Screen / Window perimeter breathing aura
            if glowOpacity > 0.01 {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        glowColor.opacity(glowOpacity * 0.9),
                        lineWidth: 3.5
                    )
                    .shadow(color: glowColor.opacity(glowOpacity * 0.8), radius: 18, x: 0, y: 0)
                    .shadow(color: glowColor.opacity(glowOpacity * 0.4), radius: 36, x: 0, y: 0)
                    .allowsHitTesting(false)
                    .ignoresSafeArea()
            }
        }
        .onChange(of: isTriggered) { _, newValue in
            if newValue {
                triggerAnimation()
            }
        }
    }
    
    private func triggerAnimation() {
        // First breathing expansion
        withAnimation(.easeIn(duration: 0.35)) {
            glowOpacity = 1.0
        }
        
        // Gentle breathing pulse
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation(.easeInOut(duration: 0.6).repeatCount(2, autoreverses: true)) {
                glowOpacity = 0.55
            }
        }
        
        // Graceful dissipation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(.easeOut(duration: 0.8)) {
                glowOpacity = 0.0
                isTriggered = false
            }
        }
    }
}

public extension View {
    func ambientCelebrationGlow(isTriggered: Binding<Bool>, glowColor: Color = Theme.accent) -> some View {
        self.modifier(AmbientCelebrationGlowModifier(isTriggered: isTriggered, glowColor: glowColor))
    }
}
