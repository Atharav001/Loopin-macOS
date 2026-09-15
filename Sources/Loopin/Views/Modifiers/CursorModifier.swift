import SwiftUI
import AppKit

// MARK: - CursorModifier
public struct CursorModifier: ViewModifier {
    public var cursor: NSCursor
    
    public init(cursor: NSCursor = .pointingHand) {
        self.cursor = cursor
    }
    
    public func body(content: Content) -> some View {
        content
            .onHover { inside in
                if inside {
                    cursor.push()
                } else {
                    NSCursor.pop()
                }
            }
    }
}

public extension View {
    func customCursor(_ cursor: NSCursor = .pointingHand) -> some View {
        self.modifier(CursorModifier(cursor: cursor))
    }
}
