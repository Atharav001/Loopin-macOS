import SwiftUI

public struct RailsView: View {
    @ObservedObject var appState: AppState = .shared
    @State private var entries: [TimesheetEntry] = []
    
    public init() {}
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 20) {
                // Quick-plan natural language input
                QuickPlanInputView(onAdded: {
                    loadEntries()
                })
                
                // Interval banner with live countdown
                IntervalBannerView()
                
                // Dual Timesheet Rails (Planned & Logged)
                TimesheetRailsView(entries: entries, onSelectEntry: { entry in
                    appState.editingEntry = entry
                    appState.showEntryEditor = true
                })
                
                // Today's blocks breakdown list
                TodayBlocksListView(
                    entries: entries,
                    onEdit: { entry in
                        appState.editingEntry = entry
                        appState.showEntryEditor = true
                    },
                    onDelete: { entry in
                        DatabaseManager.shared.deleteEntry(id: entry.id)
                        loadEntries()
                    },
                    onAddSample: {
                        SampleDataSeeder.seedSampleEntries()
                        loadEntries()
                    }
                )
            }
            .padding(24)
        }
        .onAppear {
            loadEntries()
        }
        .onReceive(NotificationCenter.default.publisher(for: DatabaseManager.didChangeNotification)) { _ in
            loadEntries()
        }
    }
    
    private func loadEntries() {
        entries = DatabaseManager.shared.fetchForDay(Date())
    }
}
