import Foundation

class LatencyProbe {
    static let shared = LatencyProbe()
    private var timer: Timer?
    @Published var currentRTT: Int = 0
    
    func start() {
        stop()
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            let now = Int(Date().timeIntervalSince1970 * 1000)
            let pingEvent = InputEvent(t: "ping", ts: now)
            ConnectionManager.shared.send(event: pingEvent)
        }
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
    }
    
    func updateRTT(_ rtt: Int) {
        DispatchQueue.main.async {
            self.currentRTT = rtt
        }
    }
}
