import SwiftUI

struct DiscoveredServer: Identifiable, Hashable {
    let id: String // IP address
    let name: String
    let port: UInt16
    var lastSeen: Date
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

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
    @Published var discoveredServers: [DiscoveredServer] = []
    @Published var showAccessibilityAlert = false
    @Published var lastHandshakeError: String? = nil
    
    private init() {}
    
    func setIP(_ ip: String) {
        serverIP = ip
        UserDefaults.standard.set(ip, forKey: "lastIP")
    }

    func updateDiscovery(ip: String, name: String, port: UInt16) {
        let server = DiscoveredServer(id: ip, name: name, port: port, lastSeen: Date())
        if let index = discoveredServers.firstIndex(where: { $0.id == ip }) {
            discoveredServers[index] = server
        } else {
            discoveredServers.append(server)
        }
    }
    
    func clearDiscovery() {
        discoveredServers.removeAll()
    }
}
