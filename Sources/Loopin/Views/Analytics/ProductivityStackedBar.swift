import SwiftUI

public struct ProductivityStackedBar: View {
    public let productiveMinutes: Int
    public let neutralMinutes: Int
    public let wastefulMinutes: Int
    
    public init(productiveMinutes: Int, neutralMinutes: Int, wastefulMinutes: Int) {
        self.productiveMinutes = productiveMinutes
        self.neutralMinutes = neutralMinutes
        self.wastefulMinutes = wastefulMinutes
    }
    
    private var totalMinutes: Int {
        productiveMinutes + neutralMinutes + wastefulMinutes
    }
    
    private var productiveFraction: Double {
        totalMinutes > 0 ? Double(productiveMinutes) / Double(totalMinutes) : 0
    }
    
    private var neutralFraction: Double {
        totalMinutes > 0 ? Double(neutralMinutes) / Double(totalMinutes) : 0
    }
    
    private var wastefulFraction: Double {
        totalMinutes > 0 ? Double(wastefulMinutes) / Double(totalMinutes) : 0
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "chart.pie.fill")
                        .foregroundColor(Theme.productive)
                    Text("Productivity Ratio")
                        .font(Theme.titleSmall)
                        .foregroundColor(Theme.textPrimary)
                }
                
                Spacer()
                
                if totalMinutes > 0 {
                    Text(String(format: "%.0f%% Productive", productiveFraction * 100))
                        .font(Theme.caption)
                        .fontWeight(.bold)
                        .foregroundColor(Theme.productive)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Theme.productiveBg)
                        .cornerRadius(6)
                }
            }
            
            // Stacked Bar
            GeometryReader { geo in
                let width = geo.size.width
                HStack(spacing: 2) {
                    if productiveFraction > 0 {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Theme.productive)
                            .frame(width: max(4, width * CGFloat(productiveFraction)))
                    }
                    if neutralFraction > 0 {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Theme.neutral)
                            .frame(width: max(4, width * CGFloat(neutralFraction)))
                    }
                    if wastefulFraction > 0 {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Theme.wasteful)
                            .frame(width: max(4, width * CGFloat(wastefulFraction)))
                    }
                    if totalMinutes == 0 {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Theme.bgDark)
                            .frame(width: width)
                    }
                }
                .frame(height: 18)
            }
            .frame(height: 18)
            
            // Legend with minutes
            HStack(spacing: 16) {
                ratioLegendItem(
                    label: "Productive",
                    minutes: productiveMinutes,
                    fraction: productiveFraction,
                    color: Theme.productive
                )
                
                ratioLegendItem(
                    label: "Neutral",
                    minutes: neutralMinutes,
                    fraction: neutralFraction,
                    color: Theme.neutral
                )
                
                ratioLegendItem(
                    label: "Wasteful",
                    minutes: wastefulMinutes,
                    fraction: wastefulFraction,
                    color: Theme.wasteful
                )
            }
        }
        .padding(16)
        .glassCard(cornerRadius: 14)
    }
    
    private func ratioLegendItem(label: String, minutes: Int, fraction: Double, color: Color) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(Theme.caption)
                    .foregroundColor(Theme.textSecondary)
                
                Text("\(minutes / 60)h \(minutes % 60)m (\(Int(round(fraction * 100)))%)")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(Theme.textPrimary)
            }
        }
    }
}
