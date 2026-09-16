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
        
        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 460),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        win.title = "Pomodoro Timer & Stopwatch"
        win.titleVisibility = .hidden
        win.titlebarAppearsTransparent = true
        win.isMovableByWindowBackground = true
        win.minSize = NSSize(width: 240, height: 280)
        win.backgroundColor = .clear
        win.isOpaque = false
        win.hasShadow = true
        win.level = isAlwaysOnTop ? .floating : .normal
        win.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        win.delegate = self
        
        // Centered on screen by default
        win.center()
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

// MARK: - FocusTimerContainerView (Tahoe Liquid Glass Host)
struct FocusTimerContainerView: View {
    @Binding var isAlwaysOnTop: Bool
    var onClose: () -> Void
    
    var body: some View {
        ZStack {
            // Liquid Glass Background
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                .ignoresSafeArea()
            
            // Specular Gradient Mesh Tint
            LinearGradient(
                colors: [
                    Color(red: 20/255, green: 24/255, blue: 30/255).opacity(0.85),
                    Color(red: 14/255, green: 17/255, blue: 22/255).opacity(0.92)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            FocusTimerView(isAlwaysOnTop: $isAlwaysOnTop, onClose: onClose)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.22),
                            Color.white.opacity(0.06),
                            Color.white.opacity(0.02)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
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
