import SwiftUI

public struct WeekCalendarView: View {
    @ObservedObject var appState: AppState = .shared
    @State private var entries: [TimesheetEntry] = []
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 16) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .foregroundColor(Theme.accentLight)
                    Text("Week Calendar (Clockify Grid)")
                        .font(Theme.titleMedium)
                        .foregroundColor(Theme.textPrimary)
                }
                
                Spacer()
                
                Text("Phase 3 & 4: Interactive 7×24 Grid")
                    .font(Theme.caption)
                    .foregroundColor(Theme.textSecondary)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            
            // Grid content will be fully implemented in Phase 3 & 4
            ZStack {
                Theme.bgDark.opacity(0.5)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 1))
                
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 44))
                        .foregroundColor(Theme.accent.opacity(0.8))
                    
                    Text("Week Calendar Grid")
                        .font(Theme.titleSmall)
                        .foregroundColor(Theme.textPrimary)
                    
                    Text("7 Day-Columns × 24-Hours with Clockify-style drag to create, resize, and move.")
                        .font(Theme.caption)
                        .foregroundColor(Theme.textSecondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }
}
