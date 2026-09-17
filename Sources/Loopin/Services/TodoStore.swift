import SwiftUI
import Combine
import AppKit

// MARK: - TodoStore
@MainActor
public final class TodoStore: ObservableObject {
    public static let shared = TodoStore()
    
    private let itemsKey = "Logtrackin_TodoItems_v1"
    private let themeKey = "Logtrackin_TodoPaneTheme_v1"
    
    @Published public var items: [TodoItem] = [] {
        didSet {
            saveItems()
        }
    }
    
    @Published public var paneTheme: TodoPaneTheme = .stickyAmber {
        didSet {
            saveTheme()
        }
    }
    
    @Published public var filter: TodoFilter = .all
    
    public init() {
        loadTheme()
        loadItems()
    }
    
    // MARK: - Filtered List
    public var filteredItems: [TodoItem] {
        let baseList: [TodoItem]
        switch filter {
        case .all:
            baseList = items
        case .active:
            baseList = items.filter { !$0.isCompleted }
        case .starred:
            baseList = items.filter { $0.isStarred }
        case .completed:
            baseList = items.filter { $0.isCompleted }
        }
        
        // First task added stays on top, tasks added at the end stay at the last (FIFO order)
        // Completed tasks move to the bottom while preserving their relative order
        return baseList.sorted { lhs, rhs in
            if lhs.isCompleted != rhs.isCompleted {
                return !lhs.isCompleted && rhs.isCompleted
            }
            if lhs.orderIndex != rhs.orderIndex {
                return lhs.orderIndex < rhs.orderIndex
            }
            return lhs.createdAt < rhs.createdAt
        }
    }
    
    // MARK: - Stats
    public var totalCount: Int {
        items.count
    }
    
    public var completedCount: Int {
        items.filter { $0.isCompleted }.count
    }
    
    public var pendingCount: Int {
        items.filter { !$0.isCompleted }.count
    }
    
    public var progress: Double {
        guard totalCount > 0 else { return 0.0 }
        return Double(completedCount) / Double(totalCount)
    }
    
    public var summaryText: String {
        if totalCount == 0 {
            return "No tasks yet"
        } else if completedCount == totalCount {
            return "All \(totalCount) completed! 🎉"
        } else {
            return "\(completedCount) of \(totalCount) completed"
        }
    }
    
    // MARK: - Actions
    @discardableResult
    public func addTask(title: String, isStarred: Bool = false) -> Bool {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        
        let nextIndex = (items.map { $0.orderIndex }.max() ?? -1) + 1
        let newItem = TodoItem(
            title: trimmed,
            isCompleted: false,
            isStarred: isStarred,
            createdAt: Date(),
            orderIndex: nextIndex
        )
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            items.append(newItem)
        }
        
        SoundManager.shared.play(.click)
        return true
    }
    
    public func toggleCompleted(id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
            items[index].isCompleted.toggle()
            if items[index].isCompleted {
                items[index].completedAt = Date()
                SoundManager.shared.play(.success)
            } else {
                items[index].completedAt = nil
                SoundManager.shared.play(.click)
            }
        }
    }
    
    public func toggleStarred(id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        
        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
            items[index].isStarred.toggle()
        }
        SoundManager.shared.play(.click)
    }
    
    public func updateTitle(id: UUID, newTitle: String) {
        let trimmed = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let index = items.firstIndex(where: { $0.id == id }) else { return }
        
        items[index].title = trimmed
    }
    
    public func deleteTask(id: UUID) {
        withAnimation(.easeOut(duration: 0.2)) {
            items.removeAll(where: { $0.id == id })
        }
        SoundManager.shared.play(.click)
    }
    
    public func clearCompleted() {
        withAnimation(.easeInOut(duration: 0.25)) {
            items.removeAll(where: { $0.isCompleted })
        }
        SoundManager.shared.play(.click)
    }
    
    public func setPaneTheme(_ theme: TodoPaneTheme) {
        withAnimation(.easeInOut(duration: 0.25)) {
            self.paneTheme = theme
        }
    }
    
    public func copySummaryToClipboard() {
        var lines: [String] = ["# Today's To-Do List (\(summaryText))", ""]
        for item in filteredItems {
            let status = item.isCompleted ? "[x]" : "[ ]"
            let star = item.isStarred ? " ⭐" : ""
            lines.append("- \(status) \(item.title)\(star)")
        }
        let text = lines.joined(separator: "\n")
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
    
    // MARK: - Persistence
    private func saveItems() {
        if let encoded = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(encoded, forKey: itemsKey)
        }
    }
    
    private func loadItems() {
        if let data = UserDefaults.standard.data(forKey: itemsKey),
           let decoded = try? JSONDecoder().decode([TodoItem].self, from: data) {
            self.items = decoded
        } else {
            // Starter sample items so the sticky note looks instantly engaging
            self.items = [
                TodoItem(title: "Complete client sprint review", isCompleted: false, isStarred: true, orderIndex: 0),
                TodoItem(title: "Prepare design tokens & theme specs", isCompleted: false, isStarred: false, orderIndex: 1),
                TodoItem(title: "Check Pomodoro focus blocks", isCompleted: true, isStarred: false, completedAt: Date(), orderIndex: 2)
            ]
        }
    }
    
    private func saveTheme() {
        UserDefaults.standard.set(paneTheme.rawValue, forKey: themeKey)
    }
    
    private func loadTheme() {
        if let raw = UserDefaults.standard.string(forKey: themeKey),
           let saved = TodoPaneTheme(rawValue: raw) {
            self.paneTheme = saved
        }
    }
}
