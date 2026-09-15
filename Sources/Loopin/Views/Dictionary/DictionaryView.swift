import SwiftUI

public struct DictionaryView: View {
    public init() {}
    
    public var body: some View {
        VStack(spacing: 16) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "character.book.closed")
                        .foregroundColor(Theme.accentLight)
                    Text("Dictionary & Classification Rules")
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
                    Image(systemName: "text.book.closed.fill")
                        .font(.system(size: 44))
                        .foregroundColor(Theme.accent)
                    
                    Text("Auto-Categorization Rules")
                        .font(Theme.titleSmall)
                        .foregroundColor(Theme.textPrimary)
                    
                    Text("Custom phrase-to-category mappings and productivity auto-tagging.")
                        .font(Theme.caption)
                        .foregroundColor(Theme.textSecondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }
}
