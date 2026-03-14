import SwiftUI

class AppState: ObservableObject {
    static let shared = AppState()
    
    @Published var isConnected = false
    @Published var latencyMs: Int = 0
    @Published var serverIP: String = UserDefaults.standard.string(forKey: "lastIP") ?? ""
    @Published var serverPort: String = UserDefaults.standard.string(forKey: "lastPort") ?? "5123"
    @Published var needsPairing = false
    @Published var updateAvailable: UpdateInfo? = nil
    @Published var autoDiscoveredIP: String? = nil
    
    private init() {}
    
    func setIP(_ ip: String) {
        serverIP = ip
        UserDefaults.standard.set(ip, forKey: "lastIP")
    }
}
