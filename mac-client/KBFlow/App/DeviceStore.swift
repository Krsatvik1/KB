import Foundation

/// Stores paired FlowDesk server fingerprints locally across sessions.
/// OTA updates never touch this — it's in UserDefaults, not the app bundle.
struct PairedDevice: Codable {
    var name: String
    let ip: String
    let hostname: String
    let firstSeen: Date
    var lastSeen: Date
}

class DeviceStore: ObservableObject {
    static let shared = DeviceStore()

    private let key = "FlowDesk.pairedDevices"

    @Published private(set) var devices: [String: PairedDevice] = [:]  // ip -> device

    private init() {
        load()
    }

    func save(device: PairedDevice) {
        devices[device.ip] = device
        persist()
    }

    func touch(ip: String) {
        if var d = devices[ip] {
            d.lastSeen = Date()
            devices[ip] = d
            persist()
        }
    }

    func remove(ip: String) {
        devices.removeValue(forKey: ip)
        persist()
    }

    // MARK: - UserDefaults persistence

    private func persist() {
        if let data = try? JSONEncoder().encode(devices) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([String: PairedDevice].self, from: data)
        else { return }
        devices = decoded
    }
}
