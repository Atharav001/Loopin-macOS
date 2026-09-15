import SwiftUI
import AppKit

// MARK: - LoggingPanel (NSPanel subclass)
public final class LoggingPanel: NSPanel, @unchecked Sendable {
    public init(contentView: NSView) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 200),
            styleMask: [.nonactivatingPanel, .titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        self.isFloatingPanel = true
        self.level = .screenSaver // High window level to ensure visibility over full-screen Spaces
        self.becomesKeyOnlyIfNeeded = true
        self.hidesOnDeactivate = false
        self.isMovableByWindowBackground = true
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.titlebarAppearsTransparent = true
        self.titleVisibility = .hidden
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = true
        
        self.contentView = contentView
    }
}

// MARK: - LoggingPanelController
@MainActor
public final class LoggingPanelController: ObservableObject, @unchecked Sendable {
    public static let shared = LoggingPanelController()
    
    private var panel: LoggingPanel?
    
    public func show() {
        if panel == nil {
            let hostingView = NSHostingView(rootView: LoggingPanelContentView(onDismiss: { [weak self] in
                self?.close()
            }))
            panel = LoggingPanel(contentView: hostingView)
        }
        
        guard let panel = panel else { return }
        
        let isDark = AppState.shared.currentTheme.isDark
        panel.appearance = NSAppearance(named: isDark ? .darkAqua : .aqua)
        
        // Position panel at top right of main screen
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let x = screenRect.maxX - 400
            let y = screenRect.maxY - 230
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }
        
        panel.orderFrontRegardless()
    }
    
    public func close() {
        panel?.orderOut(nil)
        panel = nil
    }
}
