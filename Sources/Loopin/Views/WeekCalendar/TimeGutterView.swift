import SwiftUI

public struct TimeGutterView: View {
    public let hourHeight: CGFloat
    public let use24HourClock: Bool
    public let hours: [Int]
    
    public init(hourHeight: CGFloat = 48, use24HourClock: Bool = false, hours: [Int] = Array(0..<24)) {
        self.hourHeight = hourHeight
        self.use24HourClock = use24HourClock
        self.hours = hours
    }
    
    public var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            ForEach(hours, id: \.self) { hour in
                ZStack(alignment: .topTrailing) {
                    Text(formatHour(hour))
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(Theme.textMuted)
                        .padding(.trailing, 8)
                        .offset(y: -7) // Perfectly aligns baseline with the horizontal gridline
                }
                .frame(width: 56, height: hourHeight, alignment: .topTrailing)
            }
        }
        .frame(width: 56)
        .background(Theme.bgDark)
        .overlay(
            Rectangle()
                .fill(Theme.border)
                .frame(width: 1),
            alignment: .trailing
        )
    }
    
    private func formatHour(_ hour: Int) -> String {
        if use24HourClock {
            return String(format: "%02d:00", hour)
        } else {
            if hour == 0 {
                return "12 AM"
            } else if hour < 12 {
                return "\(hour) AM"
            } else if hour == 12 {
                return "12 PM"
            } else {
                return "\(hour - 12) PM"
            }
        }
    }
}
