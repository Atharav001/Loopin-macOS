import SwiftUI
import AppKit

// MARK: - WindowAccessor
/// Helper to configure the underlying NSWindow directly from SwiftUI.
@MainActor
public struct WindowAccessor: NSViewRepresentable {
    @Binding var window: NSWindow?
    var isPinned: Bool
    
    public init(window: Binding<NSWindow?>, isPinned: Bool = false) {
        self._window = window
        self.isPinned = isPinned
    }
    
    public func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let targetWindow = view.window {
                self.window = targetWindow
                self.configureWindow(targetWindow)
            }
        }
        return view
    }
    
    public func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            if let targetWindow = nsView.window {
                self.window = targetWindow
                self.configureWindow(targetWindow)
                targetWindow.level = self.isPinned ? .floating : .normal
            }
        }
    }
    
    private func configureWindow(_ window: NSWindow) {
        // Enforce hard technical constraints from PRD v2 §0 & §2:
        // Background must never be globally draggable
        window.isMovableByWindowBackground = false
        
        // System title bar with fullSizeContentView
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.title = "Logtrackin"
        _ = window.styleMask.insert(.fullSizeContentView)
        
        // Enforce min and default size
        window.minSize = NSSize(width: 1060, height: 680)
        
        // Window level
        window.level = isPinned ? .floating : .normal
        
        // Enable zooming/resizing and standard traffic lights
        window.styleMask.insert([.titled, .closable, .miniaturizable, .resizable])
    }
}

// MARK: - WindowDragView
/// An NSView that allows moving the window by clicking and dragging on custom navigation/header areas
public struct WindowDragArea: NSViewRepresentable {
    public init() {}
    
    public func makeNSView(context: Context) -> DraggingNSView {
        let view = DraggingNSView()
        return view
    }
    
    public func updateNSView(_ nsView: DraggingNSView, context: Context) {}
}

public final class DraggingNSView: NSView {
    public override var mouseDownCanMoveWindow: Bool {
        return true
    }
}

// MARK: - WindowDelegateHelper
@MainActor
public final class WindowDelegateHelper: NSObject, NSWindowDelegate, @unchecked Sendable {
    public static let shared = WindowDelegateHelper()
    
    public func windowShouldClose(_ sender: NSWindow) -> Bool {
        return true
    }
}
