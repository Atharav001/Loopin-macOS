import SwiftUI
import AppKit

public struct ContentView: View {
    @ObservedObject var appState: AppState = .shared
    @State private var window: NSWindow?
    @State private var isPinnedOnTop: Bool = false
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // Dark Background
            Theme.bgDeep
                .ignoresSafeArea()
            
            // Window Configuration Accessor
            WindowAccessor(window: $window, isPinned: isPinnedOnTop)
                .frame(width: 0, height: 0)
                .opacity(0)
            
            HStack(spacing: 0) {
                // Left Vertical Sidebar Navigation
                SidebarView(
                    isPinnedOnTop: $isPinnedOnTop,
                    onTogglePin: {
                        isPinnedOnTop.toggle()
                        window?.level = isPinnedOnTop ? .floating : .normal
                    },
                    onNewEntry: {
                        appState.editingEntry = nil
                        appState.showEntryEditor = true
                    }
                )
                
                // Active Screen Body driven by appState.selectedTab
                ZStack {
                    switch appState.selectedTab {
                    case .calendar:
                        CalendarView()
                    case .weekCalendar:
                        WeekCalendarView()
                    case .rails:
                        RailsView()
                    case .analytics:
                        AnalyticsView()
                    case .dictionary:
                        DictionaryView()
                    case .focusPrompts:
                        FocusSettingsView()
                    case .account:
                        AccountView()
                    case .settings:
                        SettingsView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 980, minHeight: 640)
        .id(appState.currentTheme)
        .preferredColorScheme(appState.currentTheme.isDark ? .dark : .light)
        .ambientCelebrationGlow(isTriggered: $appState.triggerCelebrationGlow, glowColor: appState.celebrationColor)
        .sheet(isPresented: $appState.showEntryEditor) {
            EntryEditorPopover(
                entry: $appState.editingEntry,
                isPresented: $appState.showEntryEditor
            )
        }
        .onAppear {
            SampleDataSeeder.seedDefaultRulesIfNeeded()
        }
        .onChange(of: appState.showFloatingLoggingPanel) { _, isShown in
            if isShown {
                LoggingPanelController.shared.show()
            } else {
                LoggingPanelController.shared.close()
            }
        }
    }
}
