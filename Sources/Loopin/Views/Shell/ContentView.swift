import SwiftUI
import AppKit

public struct ContentView: View {
    @State private var window: NSWindow?
    @State private var isPinnedOnTop: Bool = false
    
    public init() {}
    
    public var body: some View {
        ZStack {
            Theme.bgDeep
                .ignoresSafeArea()
            
            // Background Window Accessor ensuring NSWindow properties are set
            WindowAccessor(window: $window, isPinned: isPinnedOnTop)
                .frame(width: 0, height: 0)
                .opacity(0)
            
            VStack(spacing: 20) {
                // Title & pin control
                HStack {
                    Spacer()
                    Button(action: {
                        isPinnedOnTop.toggle()
                        window?.level = isPinnedOnTop ? .floating : .normal
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: isPinnedOnTop ? "pin.fill" : "pin")
                                .font(.system(size: 12))
                            Text(isPinnedOnTop ? "Pinned on Top" : "Pin on Top")
                                .font(Theme.caption)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(isPinnedOnTop ? Theme.accent.opacity(0.2) : Theme.bgSubtle)
                        .foregroundColor(isPinnedOnTop ? Theme.accentLight : Theme.textSecondary)
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(isPinnedOnTop ? Theme.accent : Theme.border, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 20)
                    .padding(.top, 16)
                }
                
                Spacer()
                
                VStack(spacing: 12) {
                    Image(systemName: "timer.circle.fill")
                        .resizable()
                        .frame(width: 64, height: 64)
                        .foregroundColor(Theme.accent)
                        .shadow(color: Theme.accentGlow, radius: 16)
                    
                    Text("Loopin")
                        .font(Theme.titleLarge)
                        .foregroundColor(Theme.textPrimary)
                    
                    Text("Native macOS Timesheet & Logbook")
                        .font(Theme.body)
                        .foregroundColor(Theme.textSecondary)
                    
                    Text("Phase 0 — Window Shell Verified")
                        .font(Theme.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Theme.productiveBg)
                        .foregroundColor(Theme.productive)
                        .cornerRadius(20)
                        .overlay(
                            Capsule().stroke(Theme.productive.opacity(0.3), lineWidth: 1)
                        )
                }
                
                Spacer()
            }
        }
        .frame(minWidth: 980, minHeight: 640)
    }
}
