import Foundation

class LatencyProbe {
    static let shared = LatencyProbe()
    private var timer: Timer?
    
    func start() {
        // Stop any existing timer first
        stop()
        
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            if ConnectionManager.shared.isConnected {
                let now = Int(Date().timeIntervalSince1970 * 1000)
                let pingEvent = InputEvent(t: "ping", ts: now)
                ConnectionManager.shared.send(event: pingEvent)
            }
        }
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
    }
}
