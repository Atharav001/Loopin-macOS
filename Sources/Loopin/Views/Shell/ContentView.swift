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
            
            VStack(spacing: 0) {
                // Top Custom Tab Navigation Bar
                TabBarView(
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
                
                // Active Screen Body driven by @State selectedTab
                ZStack {
                    switch appState.selectedTab {
                    case .rails:
                        RailsView()
                    case .weekCalendar:
                        WeekCalendarView()
                    case .analytics:
                        AnalyticsView()
                    case .dictionary:
                        DictionaryView()
                    case .focusPrompts:
                        FocusSettingsView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 980, minHeight: 640)
        .sheet(isPresented: $appState.showEntryEditor) {
            EntryEditorPopover(
                entry: $appState.editingEntry,
                isPresented: $appState.showEntryEditor
            )
        }
        .onAppear {
            SampleDataSeeder.seedDefaultRulesIfNeeded()
        }
    }
}
