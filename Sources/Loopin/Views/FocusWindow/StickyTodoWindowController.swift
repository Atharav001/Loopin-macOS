import SwiftUI
import AppKit

// MARK: - StickyTodoWindowController
@MainActor
public final class StickyTodoWindowController: NSObject, ObservableObject, NSWindowDelegate {
    public static let shared = StickyTodoWindowController()
    
    private var window: NSWindow?
    @Published public var isAlwaysOnTop: Bool = true {
        didSet {
            window?.level = isAlwaysOnTop ? .floating : .normal
        }
    }
    
    public override init() {
        super.init()
    }
    
    public func show() {
        if window == nil {
            createWindow()
        }
        
        guard let window = window else { return }
        
        // Smart placement: if window is not already placed, position it side-by-side with Pomodoro timer
        if window.frame.origin == .zero || !window.isVisible {
            if let screen = NSScreen.main {
                let screenFrame = screen.visibleFrame
                let winWidth: CGFloat = window.frame.width > 0 ? window.frame.width : 340
                let winHeight: CGFloat = window.frame.height > 0 ? window.frame.height : 480
                
                // Position to the left of the Pomodoro timer window (which is at maxX - 380 - 20)
                // If screen is wide, position side by side (maxX - 380 - 20 - winWidth - 16)
                // Otherwise place at top-right with slight offset
                var x = screenFrame.maxX - 380 - 20 - winWidth - 16
                if x < screenFrame.minX + 20 {
                    x = screenFrame.maxX - winWidth - 30
                }
                let y = screenFrame.maxY - winHeight - 20
                window.setFrame(NSRect(x: x, y: y, width: winWidth, height: winHeight), display: true)
            }
        }
        
        window.level = isAlwaysOnTop ? .floating : .normal
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    public func toggle() {
        if let window = window, window.isVisible {
            window.orderOut(nil)
        } else {
            show()
        }
    }
    
    public func hide() {
        window?.orderOut(nil)
    }
    
    private func createWindow() {
        let hostingView = NSHostingView(
            rootView: StickyTodoContainerView(
                isAlwaysOnTop: Binding(
                    get: { [weak self] in self?.isAlwaysOnTop ?? true },
                    set: { [weak self] val in self?.isAlwaysOnTop = val }
                ),
                onClose: { [weak self] in
                    self?.window?.orderOut(nil)
                }
            )
        )
        
        let winWidth: CGFloat = 340
        let winHeight: CGFloat = 480
        
        var initialFrame = NSRect(x: 0, y: 0, width: winWidth, height: winHeight)
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            var x = screenFrame.maxX - 380 - 20 - winWidth - 16
            if x < screenFrame.minX + 20 {
                x = screenFrame.maxX - winWidth - 30
            }
            let y = screenFrame.maxY - winHeight - 20
            initialFrame = NSRect(x: x, y: y, width: winWidth, height: winHeight)
        }
        
        let win = NSWindow(
            contentRect: initialFrame,
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        win.title = "Today's Tasks • Sticky Note"
        win.titleVisibility = .hidden
        win.titlebarAppearsTransparent = true
        win.isMovableByWindowBackground = true
        win.minSize = NSSize(width: 280, height: 320)
        win.backgroundColor = NSColor(red: 16/255, green: 14/255, blue: 18/255, alpha: 1.0)
        win.isOpaque = true
        win.hasShadow = true
        win.appearance = NSAppearance(named: .darkAqua)
        win.level = isAlwaysOnTop ? .floating : .normal
        win.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        win.delegate = self
        
        win.setFrame(initialFrame, display: true)
        win.contentView = hostingView
        self.window = win
    }
    
    public func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        return false
    }
    
    public func windowWillClose(_ notification: Notification) {
        // Retain window reference for fast re-opening
    }
}

// MARK: - StickyTodoContainerView
public struct StickyTodoContainerView: View {
    @ObservedObject private var store = TodoStore.shared
    @Binding var isAlwaysOnTop: Bool
    var onClose: () -> Void
    
    public init(isAlwaysOnTop: Binding<Bool>, onClose: @escaping () -> Void) {
        self._isAlwaysOnTop = isAlwaysOnTop
        self.onClose = onClose
    }
    
    public var body: some View {
        ZStack {
            // Adaptive gradient matching the active Sticky Note theme
            LinearGradient(
                colors: [
                    store.paneTheme.bgCanvasTop,
                    store.paneTheme.bgCanvasBottom
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Subtle ambient vignette / radial glow from top center
            RadialGradient(
                colors: [
                    store.paneTheme.accent.opacity(0.12),
                    Color.clear
                ],
                center: .top,
                startRadius: 10,
                endRadius: 280
            )
            .ignoresSafeArea()
            
            StickyTodoView(isAlwaysOnTop: $isAlwaysOnTop, onClose: onClose)
        }
        .ignoresSafeArea(.all)
    }
}
