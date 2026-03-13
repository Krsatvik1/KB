import Cocoa

class MouseTracker {
    static let shared = MouseTracker()
    
    func start() {
        // Hide OS cursor and decouple it from physical mouse location
        NSCursor.hide()
        CGAssociateMouseAndMouseCursorPosition(0)
    }
    
    func stop() {
        CGAssociateMouseAndMouseCursorPosition(1)
        NSCursor.unhide()
    }
}
