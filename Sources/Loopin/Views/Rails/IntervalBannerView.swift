import SwiftUI

public struct IntervalBannerView: View {
    @ObservedObject var appState: AppState = .shared
    @State private var isHovered: Bool = false
    
    public init() {}
    
    public var body: some View {
        HStack(spacing: 16) {
            // Live Status Indicator & Timer
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Theme.accent.opacity(0.2))
                        .frame(width: 24, height: 24)
                    
                    Circle()
                        .fill(Theme.accent)
                        .frame(width: 8, height: 8)
                        .shadow(color: Theme.accent, radius: 4)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Interval Logging Active")
                        .font(Theme.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.textPrimary)
                    
                    HStack(spacing: 4) {
                        Text("Next prompt in:")
                            .font(Theme.caption)
                            .foregroundColor(Theme.textSecondary)
                        Text(appState.formattedCountdown)
                            .font(Theme.monoBold)
                            .foregroundColor(Theme.accentLight)
                    }
                }
            }
            
            Spacer()
            
            // Interval preset buttons
            HStack(spacing: 6) {
                ForEach([15, 30, 45, 60], id: \.self) { minutes in
                    let isSelected = appState.selectedIntervalMinutes == minutes
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            appState.setIntervalMinutes(minutes)
                        }
                    }) {
                        Text(minutes == 60 ? "1h" : "\(minutes)m")
                            .font(Theme.caption)
                            .fontWeight(isSelected ? .bold : .medium)
                            .foregroundColor(isSelected ? .white : Theme.textSecondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(isSelected ? Theme.accent : Theme.bgSubtle)
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(isSelected ? Theme.accentLight.opacity(0.6) : Theme.border, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Divider()
                .frame(height: 20)
                .background(Theme.border)
            
            // Quick Trigger Prompt Button
            Button(action: {
                appState.showFloatingLoggingPanel = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 12))
                    Text("Log Now")
                        .font(Theme.caption)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Theme.accent)
                .cornerRadius(8)
                .shadow(color: Theme.accentGlow, radius: 4)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .glassCard(cornerRadius: 12, strokeColor: isHovered ? Theme.accent.opacity(0.3) : Theme.border)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}
