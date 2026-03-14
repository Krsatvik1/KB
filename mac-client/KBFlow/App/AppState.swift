import SwiftUI

class AppState: ObservableObject {
    static let shared = AppState()
    
    @Published var isConnected = false
    @Published var latencyMs = 0
    @Published var serverIP = ""
    @Published var serverPort = "5123"
    @Published var serverName = "Windows PC"
    @Published var clientName = Host.current().localizedName ?? "Mac"
    @Published var needsPairing = false
    @Published var updateAvailable: UpdateInfo? = nil
    @Published var autoDiscoveredIP: String? = nil
    @Published var showAccessibilityAlert = false
    
    private init() {}
    
    func setIP(_ ip: String) {
        serverIP = ip
        UserDefaults.standard.set(ip, forKey: "lastIP")
    }
}
