import SwiftUI

public struct TimeGutterView: View {
    public let hourHeight: CGFloat
    private let totalHours: Int = 24
    
    public init(hourHeight: CGFloat = 48) {
        self.hourHeight = hourHeight
    }
    
    public var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            ForEach(0..<totalHours, id: \.self) { hour in
                ZStack(alignment: .topTrailing) {
                    Text(String(format: "%02d:00", hour))
                        .font(Theme.caption)
                        .foregroundColor(Theme.textMuted)
                        .padding(.trailing, 8)
                        .offset(y: -7) // Center text with the top gridline
                }
                .frame(width: 52, height: hourHeight, alignment: .topTrailing)
            }
        }
        .frame(width: 52)
        .background(Theme.bgDark)
        .overlay(
            Rectangle()
                .fill(Theme.border)
                .frame(width: 1),
            alignment: .trailing
        )
    }
}
