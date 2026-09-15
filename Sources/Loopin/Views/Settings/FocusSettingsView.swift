import SwiftUI

public struct FocusSettingsView: View {
    public init() {}
    
    public var body: some View {
        VStack(spacing: 16) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundColor(Theme.accentLight)
                    Text("Focus & Prompts Settings")
                        .font(Theme.titleMedium)
                        .foregroundColor(Theme.textPrimary)
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            
            ZStack {
                Theme.bgDark.opacity(0.5)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 1))
                
                VStack(spacing: 12) {
                    Image(systemName: "timer")
                        .font(.system(size: 44))
                        .foregroundColor(Theme.neutral)
                    
                    Text("Interval Logging & Quiet Hours")
                        .font(Theme.titleSmall)
                        .foregroundColor(Theme.textPrimary)
                    
                    Text("Prompt schedule, overnight quiet hours, Pomodoro timer, and sound settings.")
                        .font(Theme.caption)
                        .foregroundColor(Theme.textSecondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }
}
