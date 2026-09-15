import SwiftUI
import AppKit

// MARK: - InteractionNSView
public final class InteractionNSView: NSView {
    public var onDragBegan: ((CGPoint) -> Void)?
    public var onDragChanged: ((CGPoint, CGPoint) -> Void)?
    public var onDragEnded: ((CGPoint, CGPoint) -> Void)?
    public var onSingleClick: ((CGPoint) -> Void)?
    
    private var dragStart: CGPoint?
    private var hasMoved: Bool = false
    
    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
    }
    
    public override var isFlipped: Bool {
        return true
    }
    
    public override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }
    
    public override func mouseDown(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        dragStart = location
        hasMoved = false
        onDragBegan?(location)
    }
    
    public override func mouseDragged(with event: NSEvent) {
        guard let start = dragStart else { return }
        let current = convert(event.locationInWindow, from: nil)
        
        if abs(current.y - start.y) > 3 || abs(current.x - start.x) > 3 {
            hasMoved = true
        }
        
        if hasMoved {
            onDragChanged?(start, current)
        }
    }
    
    public override func mouseUp(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        if let start = dragStart {
            if hasMoved {
                onDragEnded?(start, location)
            } else {
                onSingleClick?(location)
            }
        }
        dragStart = nil
        hasMoved = false
    }
}

// MARK: - GridInteractionView
public struct GridInteractionView: NSViewRepresentable {
    public var onDragBegan: ((CGPoint) -> Void)?
    public var onDragChanged: ((CGPoint, CGPoint) -> Void)?
    public var onDragEnded: ((CGPoint, CGPoint) -> Void)?
    public var onSingleClick: ((CGPoint) -> Void)?
    
    public init(
        onDragBegan: ((CGPoint) -> Void)? = nil,
        onDragChanged: ((CGPoint, CGPoint) -> Void)? = nil,
        onDragEnded: ((CGPoint, CGPoint) -> Void)? = nil,
        onSingleClick: ((CGPoint) -> Void)? = nil
    ) {
        self.onDragBegan = onDragBegan
        self.onDragChanged = onDragChanged
        self.onDragEnded = onDragEnded
        self.onSingleClick = onSingleClick
    }
    
    public func makeNSView(context: Context) -> InteractionNSView {
        let view = InteractionNSView(frame: .zero)
        view.onDragBegan = onDragBegan
        view.onDragChanged = onDragChanged
        view.onDragEnded = onDragEnded
        view.onSingleClick = onSingleClick
        return view
    }
    
    public func updateNSView(_ nsView: InteractionNSView, context: Context) {
        nsView.onDragBegan = onDragBegan
        nsView.onDragChanged = onDragChanged
        nsView.onDragEnded = onDragEnded
        nsView.onSingleClick = onSingleClick
    }
}
