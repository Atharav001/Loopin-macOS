import SwiftUI

// MARK: - CategoryStat
public struct CategoryStat: Identifiable, Equatable {
    public var id: String { name }
    public let name: String
    public let totalMinutes: Int
    public let productivity: ProductivityType
    public let percentage: Double
    
    public var formattedDuration: String {
        let hrs = totalMinutes / 60
        let mins = totalMinutes % 60
        if hrs == 0 {
            return "\(mins)m"
        } else if mins == 0 {
            return "\(hrs)h"
        } else {
            return "\(hrs)h \(mins)m"
        }
    }
}

// MARK: - CategoryBarChart
public struct CategoryBarChart: View {
    public let stats: [CategoryStat]
    @State private var hoveredCategory: String?
    
    public init(stats: [CategoryStat]) {
        self.stats = stats
    }
    
    private var maxMinutes: Int {
        max(1, stats.map { $0.totalMinutes }.max() ?? 1)
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(Theme.accentLight)
                    Text("Time by Category")
                        .font(Theme.titleSmall)
                        .foregroundColor(Theme.textPrimary)
                }
                Spacer()
            }
            
            if stats.isEmpty {
                Text("No logged entries in selected time range.")
                    .font(Theme.caption)
                    .foregroundColor(Theme.textMuted)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 10) {
                    ForEach(stats) { stat in
                        let isHovered = hoveredCategory == stat.name
                        let color = Color.forProductivity(stat.productivity)
                        let barFraction = CGFloat(stat.totalMinutes) / CGFloat(maxMinutes)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(stat.name)
                                    .font(Theme.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Theme.textPrimary)
                                
                                Spacer()
                                
                                Text(stat.formattedDuration)
                                    .font(Theme.monoBold)
                                    .foregroundColor(Theme.textPrimary)
                                
                                Text(String(format: "(%.1f%%)", stat.percentage * 100))
                                    .font(Theme.caption)
                                    .foregroundColor(Theme.textSecondary)
                                    .frame(width: 50, alignment: .trailing)
                            }
                            
                            // Bar geometry
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(Theme.bgDark)
                                        .frame(height: 10)
                                    
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(color)
                                        .frame(width: max(8, geo.size.width * barFraction), height: 10)
                                        .shadow(color: isHovered ? color.opacity(0.6) : Color.clear, radius: 4)
                                }
                            }
                            .frame(height: 10)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(isHovered ? Theme.bgCardHover : Color.clear)
                        .cornerRadius(8)
                        .onHover { hovering in
                            withAnimation(.easeInOut(duration: 0.15)) {
                                hoveredCategory = hovering ? stat.name : nil
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .glassCard(cornerRadius: 14)
    }
}
