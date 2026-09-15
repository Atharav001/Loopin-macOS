import SwiftUI

public struct AnalyticsView: View {
    public init() {}
    
    public var body: some View {
        VStack(spacing: 16) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "chart.bar.xaxis")
                        .foregroundColor(Theme.accentLight)
                    Text("Analytics & Reports")
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
                    Image(systemName: "chart.pie.fill")
                        .font(.system(size: 44))
                        .foregroundColor(Theme.productive)
                    
                    Text("Time & Productivity Insights")
                        .font(Theme.titleSmall)
                        .foregroundColor(Theme.textPrimary)
                    
                    Text("Aggregated daily/weekly category distributions, productive vs wasteful ratios.")
                        .font(Theme.caption)
                        .foregroundColor(Theme.textSecondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }
}
