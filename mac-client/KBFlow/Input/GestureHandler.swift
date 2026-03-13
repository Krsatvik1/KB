import Cocoa

class GestureHandler {
    static let shared = GestureHandler()
    private var monitor: Any?
    
    func start() {
        monitor = NSEvent.addLocalMonitorForEvents(matching: .any) { event in
            // Handle 4-finger gestures for exiting the application
            let touches = event.touches(matching: .touching, in: nil)
            if touches.count == 4 {
                self.handleFourFingerSwipe()
            }
            return event
        }
    }
    
    func stop() {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }
    
    private func handleFourFingerSwipe() {
        print("4-finger gesture detected, exiting KBFlow...")
        EventInterceptor.shared.stop()
        MouseTracker.shared.stop()
        
        NSApp.presentationOptions = []
        NSApp.terminate(nil)
    }
}
