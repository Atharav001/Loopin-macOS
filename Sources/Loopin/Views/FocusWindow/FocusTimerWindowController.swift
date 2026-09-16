import SwiftUI
import AppKit

// MARK: - FocusTimerWindowController
@MainActor
public final class FocusTimerWindowController: NSObject, ObservableObject, NSWindowDelegate {
    public static let shared = FocusTimerWindowController()
    
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
        
        // Always place in top right area of visible screen
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let winWidth: CGFloat = window.frame.width > 0 ? window.frame.width : 380
            let winHeight: CGFloat = window.frame.height > 0 ? window.frame.height : 460
            let x = screenFrame.maxX - winWidth - 20
            let y = screenFrame.maxY - winHeight - 20
            window.setFrame(NSRect(x: x, y: y, width: winWidth, height: winHeight), display: true)
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
    
    private func createWindow() {
        let hostingView = NSHostingView(
            rootView: FocusTimerContainerView(
                isAlwaysOnTop: Binding(
                    get: { [weak self] in self?.isAlwaysOnTop ?? true },
                    set: { [weak self] val in self?.isAlwaysOnTop = val }
                ),
                onClose: { [weak self] in
                    self?.window?.orderOut(nil)
                }
            )
        )
        
        let winWidth: CGFloat = 380
        let winHeight: CGFloat = 460
        
        var initialFrame = NSRect(x: 0, y: 0, width: winWidth, height: winHeight)
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.maxX - winWidth - 20
            let y = screenFrame.maxY - winHeight - 20
            initialFrame = NSRect(x: x, y: y, width: winWidth, height: winHeight)
        }
        
        let win = NSWindow(
            contentRect: initialFrame,
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        win.title = "Pomodoro Timer & Stopwatch"
        win.titleVisibility = .hidden
        win.titlebarAppearsTransparent = true
        win.isMovableByWindowBackground = true
        win.minSize = NSSize(width: 240, height: 280)
        win.backgroundColor = NSColor(red: 12/255, green: 14/255, blue: 18/255, alpha: 1.0)
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
        // Keep window reference
    }
}

// MARK: - FocusTimerContainerView (Seamless Dark Window Host)
struct FocusTimerContainerView: View {
    @Binding var isAlwaysOnTop: Bool
    var onClose: () -> Void
    
    var body: some View {
        ZStack {
            // Dark obsidian canvas background that covers full window including titlebar
            Color(red: 10/255, green: 12/255, blue: 16/255)
                .ignoresSafeArea()
            
            // Subtle ambient gradient tint
            LinearGradient(
                colors: [
                    Color(red: 18/255, green: 22/255, blue: 28/255),
                    Color(red: 10/255, green: 12/255, blue: 16/255)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            FocusTimerView(isAlwaysOnTop: $isAlwaysOnTop, onClose: onClose)
        }
        .ignoresSafeArea(.all)
    }
}

// MARK: - NSVisualEffectView Bridge
struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
