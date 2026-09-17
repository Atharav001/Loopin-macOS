import SwiftUI
import AppKit

// MARK: - StickyTodoView
public struct StickyTodoView: View {
    @ObservedObject private var store = TodoStore.shared
    @Binding var isAlwaysOnTop: Bool
    var onClose: () -> Void
    
    // Quick Add State
    @State private var newTaskTitle: String = ""
    @State private var isNewTaskStarred: Bool = false
    @FocusState private var isInputFocused: Bool
    
    // Inline Edit State
    @State private var editingItemId: UUID? = nil
    @State private var editingText: String = ""
    @FocusState private var isEditFocused: Bool
    
    // Hovered Item
    @State private var hoveredItemId: UUID? = nil
    
    // Show Theme Menu
    @State private var isShowingThemePicker: Bool = false
    
    public init(isAlwaysOnTop: Binding<Bool>, onClose: @escaping () -> Void) {
        self._isAlwaysOnTop = isAlwaysOnTop
        self.onClose = onClose
    }
    
    public var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let isCompact = w < 310
            
            VStack(spacing: 0) {
                // 1. Sleek Navigation Header (anchors traffic lights, theme picker, pin)
                navigationBar(isCompact: isCompact)
                
                // 2. Filter / Aspect Selector Bar
                filterSegmentBar(isCompact: isCompact)
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                    .padding(.bottom, 6)
                
                // 3. Rapid Multi-Task Input Bar
                quickInputBar
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
                
                // 4. Scrollable Single Task Pane
                taskListView
                
                // 5. Footer Progress & Actions Bar
                footerBar(isCompact: isCompact)
            }
        }
    }
    
    // MARK: - 1. Navigation Header
    private func navigationBar(isCompact: Bool) -> some View {
        HStack(spacing: 8) {
            // Space reserved for macOS traffic lights (close, min, zoom)
            Spacer()
                .frame(width: 66)
            
            // Pane Title & Progress Pill
            HStack(spacing: 6) {
                Image(systemName: "checklist")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(store.paneTheme.accent)
                
                Text(isCompact ? "Tasks" : "Today's Tasks")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                if store.totalCount > 0 {
                    Text("\(store.completedCount)/\(store.totalCount)")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1.5)
                        .background(store.paneTheme.accent.opacity(0.2))
                        .foregroundColor(store.paneTheme.accentLight)
                        .clipShape(Capsule())
                }
            }
            
            Spacer()
            
            // Color Palette Selector Menu
            Menu {
                Section(header: Text("Sticky Note Theme")) {
                    ForEach(TodoPaneTheme.allCases) { theme in
                        Button(action: {
                            store.setPaneTheme(theme)
                        }) {
                            HStack {
                                Text(theme.displayName)
                                if store.paneTheme == theme {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 3) {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [store.paneTheme.accentLight, store.paneTheme.accent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 10, height: 10)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 0.8)
                        )
                    
                    Image(systemName: "paintpalette.fill")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(store.paneTheme.accentLight)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3.5)
                .background(Color.white.opacity(0.06))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(store.paneTheme.accent.opacity(0.3), lineWidth: 0.8)
                )
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .help("Change Sticky Note Color Theme")
            
            // Always-On-Top Pin Toggle
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isAlwaysOnTop.toggle()
                }
            }) {
                Image(systemName: isAlwaysOnTop ? "pin.fill" : "pin")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(isAlwaysOnTop ? store.paneTheme.accentLight : Color.white.opacity(0.45))
                    .padding(5)
                    .background(isAlwaysOnTop ? store.paneTheme.accent.opacity(0.2) : Color.white.opacity(0.05))
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(isAlwaysOnTop ? store.paneTheme.accent.opacity(0.4) : Color.clear, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .help(isAlwaysOnTop ? "Pinned on Top" : "Pin on Top")
            
            // More Menu
            Menu {
                Button(action: {
                    store.copySummaryToClipboard()
                }) {
                    Label("Copy Today's Summary", systemImage: "doc.on.doc")
                }
                
                Button(action: {
                    FocusTimerWindowController.shared.show()
                }) {
                    Label("Open Pomodoro Timer", systemImage: "timer")
                }
                
                if store.completedCount > 0 {
                    Divider()
                    Button(role: .destructive, action: {
                        store.clearCompleted()
                    }) {
                        Label("Clear Completed Tasks", systemImage: "trash")
                    }
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color.white.opacity(0.55))
                    .padding(5)
                    .background(Color.white.opacity(0.05))
                    .clipShape(Circle())
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .help("More Options")
        }
        .padding(.horizontal, 10)
        .frame(height: 34)
        .background(
            Color.black.opacity(0.3)
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color.white.opacity(0.06)),
                    alignment: .bottom
                )
        )
    }
    
    // MARK: - 2. Filter Segment Bar
    private func filterSegmentBar(isCompact: Bool) -> some View {
        HStack(spacing: 4) {
            ForEach(TodoFilter.allCases) { filterOption in
                let isSelected = store.filter == filterOption
                Button(action: {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                        store.filter = filterOption
                    }
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: filterOption.icon)
                            .font(.system(size: 8, weight: .semibold))
                        
                        if !isCompact || isSelected {
                            Text(filterOption.rawValue)
                                .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                        }
                    }
                    .foregroundColor(isSelected ? .white : Color.white.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                    .background(
                        isSelected ?
                            LinearGradient(
                                colors: [store.paneTheme.accent, store.paneTheme.accent.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(colors: [Color.white.opacity(0.04), Color.white.opacity(0.04)], startPoint: .top, endPoint: .bottom)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isSelected ? store.paneTheme.accentLight.opacity(0.4) : Color.white.opacity(0.04), lineWidth: 0.8)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2)
        .background(Color.black.opacity(0.25))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    // MARK: - 3. Rapid Multi-Task Input Bar
    private var quickInputBar: some View {
        HStack(spacing: 6) {
            // Star toggle for the task being added
            Button(action: {
                isNewTaskStarred.toggle()
            }) {
                Image(systemName: isNewTaskStarred ? "star.fill" : "star")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(isNewTaskStarred ? Color(red: 245/255, green: 158/255, blue: 11/255) : Color.white.opacity(0.3))
                    .padding(5)
            }
            .buttonStyle(.plain)
            .help(isNewTaskStarred ? "Will be added as Starred" : "Click to add as Starred")
            
            // Rapid text entry field
            TextField("Add a task for today... (⏎ to add)", text: $newTaskTitle)
                .textFieldStyle(.plain)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white)
                .focused($isInputFocused)
                .onSubmit {
                    submitNewTask()
                }
            
            if !newTaskTitle.isEmpty {
                Button(action: {
                    submitNewTask()
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(store.paneTheme.accentLight)
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 9)
                .fill(Color.black.opacity(0.4))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 9)
                .stroke(
                    isInputFocused ? store.paneTheme.accent.opacity(0.7) : store.paneTheme.borderStroke,
                    lineWidth: isInputFocused ? 1.2 : 0.8
                )
        )
        .shadow(color: isInputFocused ? store.paneTheme.glowColor.opacity(0.25) : .clear, radius: 5)
    }
    
    private func submitNewTask() {
        guard !newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let starred = isNewTaskStarred
        let added = store.addTask(title: newTaskTitle, isStarred: starred)
        if added {
            newTaskTitle = ""
            isNewTaskStarred = false
            // Keep keyboard focus immediately for rapid multi-task entry!
            isInputFocused = true
        }
    }
    
    // MARK: - 4. Task List Pane
    private var taskListView: some View {
        ScrollView {
            LazyVStack(spacing: 5) {
                if store.filteredItems.isEmpty {
                    emptyStateView
                        .padding(.top, 40)
                } else {
                    ForEach(store.filteredItems) { item in
                        taskRow(for: item)
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .top)),
                                removal: .opacity.combined(with: .scale(scale: 0.9))
                            ))
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - Task Row
    private func taskRow(for item: TodoItem) -> some View {
        let isHovered = hoveredItemId == item.id
        let isEditing = editingItemId == item.id
        
        return HStack(spacing: 8) {
            // Checkbox with spring bounce
            Button(action: {
                store.toggleCompleted(id: item.id)
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(
                            item.isCompleted ? store.paneTheme.accent : Color.white.opacity(0.3),
                            lineWidth: 1.2
                        )
                        .frame(width: 16, height: 16)
                    
                    if item.isCompleted {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(store.paneTheme.accent)
                            .frame(width: 16, height: 16)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .black))
                            .foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(.plain)
            
            // Task Title / Inline Edit
            if isEditing {
                TextField("Task title", text: $editingText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white)
                    .focused($isEditFocused)
                    .onSubmit {
                        store.updateTitle(id: item.id, newTitle: editingText)
                        editingItemId = nil
                    }
            } else {
                Text(item.title)
                    .font(.system(size: 11, weight: item.isStarred ? .semibold : .regular))
                    .foregroundColor(item.isCompleted ? Color.white.opacity(0.35) : (item.isStarred ? .white : Color.white.opacity(0.9)))
                    .strikethrough(item.isCompleted, color: Color.white.opacity(0.3))
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) {
                        editingItemId = item.id
                        editingText = item.title
                        isEditFocused = true
                    }
            }
            
            // Star Button
            Button(action: {
                store.toggleStarred(id: item.id)
            }) {
                Image(systemName: item.isStarred ? "star.fill" : "star")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(item.isStarred ? Color(red: 245/255, green: 158/255, blue: 11/255) : Color.white.opacity(0.2))
                    .padding(3)
            }
            .buttonStyle(.plain)
            .help(item.isStarred ? "Unstar Task" : "Star Task (Priority)")
            
            // Delete button (visible on hover or active edit)
            if isHovered || isEditing {
                Button(action: {
                    store.deleteTask(id: item.id)
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color.red.opacity(0.75))
                        .padding(3)
                }
                .buttonStyle(.plain)
                .help("Delete Task")
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    item.isStarred && !item.isCompleted ?
                        store.paneTheme.accent.opacity(0.12) :
                        (isHovered ? store.paneTheme.cardHover : store.paneTheme.cardBg)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    item.isStarred && !item.isCompleted ?
                        store.paneTheme.accent.opacity(0.4) :
                        (isHovered ? Color.white.opacity(0.12) : Color.white.opacity(0.04)),
                    lineWidth: 0.8
                )
        )
        .onHover { hovering in
            hoveredItemId = hovering ? item.id : nil
        }
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(store.paneTheme.accent.opacity(0.1))
                    .frame(width: 48, height: 48)
                
                Image(systemName: store.filter.icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(store.paneTheme.accentLight)
            }
            
            Text(emptyStateTitle)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
            
            Text(emptyStateSubtitle)
                .font(.system(size: 10))
                .foregroundColor(Color.white.opacity(0.45))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
    }
    
    private var emptyStateTitle: String {
        switch store.filter {
        case .all: return "All Clear for Today!"
        case .active: return "No Pending Tasks"
        case .starred: return "No Starred Tasks"
        case .completed: return "No Completed Tasks Yet"
        }
    }
    
    private var emptyStateSubtitle: String {
        switch store.filter {
        case .all: return "Type in the input box above and press Return to start your list."
        case .active: return "You've crushed all your tasks! Enjoy the focus streak."
        case .starred: return "Click the star icon on any task to mark it as high priority."
        case .completed: return "Check off tasks as you complete them throughout the day."
        }
    }
    
    // MARK: - 5. Footer Bar
    private func footerBar(isCompact: Bool) -> some View {
        VStack(spacing: 0) {
            // Dynamic Progress Line
            GeometryReader { pGeo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 2)
                    
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [store.paneTheme.accent, store.paneTheme.accentLight],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, pGeo.size.width * CGFloat(store.progress)), height: 2)
                }
            }
            .frame(height: 2)
            
            HStack {
                // Summary text
                Text(store.summaryText)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.6))
                
                Spacer()
                
                // Clear Done action
                if store.completedCount > 0 {
                    Button(action: {
                        store.clearCompleted()
                    }) {
                        HStack(spacing: 2) {
                            Image(systemName: "xmark.circle")
                                .font(.system(size: 9))
                            Text("Clear Done")
                                .font(.system(size: 9, weight: .semibold))
                        }
                        .foregroundColor(Color.white.opacity(0.45))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2.5)
                        .background(Color.white.opacity(0.06))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .help("Remove completed tasks")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.35))
        }
    }
}
