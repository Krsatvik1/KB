import Foundation
import Network

/// Listens for UDP FlowDesk discovery beacons on port 5124.
/// When found, calls `onDiscovered` with the server IP and port.
class DiscoveryListener {
    static let shared = DiscoveryListener()

    var onDiscovered: ((String, UInt16) -> Void)?

    private var listener: NWListener?
    private let queue = DispatchQueue(label: "flowdesk.discovery", qos: .userInitiated)

    func start() {
        do {
            let params = NWParameters.udp
            params.allowLocalEndpointReuse = true
            listener = try NWListener(using: params, on: 5124)
            listener?.newConnectionHandler = { [weak self] conn in
                self?.receive(on: conn)
            }
            listener?.start(queue: queue)
            print("Discovery listener started on UDP 5124")
        } catch {
            print("Discovery listener error: \(error)")
        }
    }

    func stop() {
        listener?.cancel()
        listener = nil
    }

    private func receive(on conn: NWConnection) {
        conn.start(queue: queue)
        conn.receiveMessage { [weak self] data, _, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let name = json["name"] as? String, name == "FlowDesk",
                  let port = json["port"] as? Int,
                  case let .hostPort(host, _) = conn.endpoint
            else { return }

            let ip = "\(host)"
            let serverName = json["server_name"] as? String ?? "Windows PC"
            
            DispatchQueue.main.async {
                AppState.shared.updateDiscovery(ip: ip, name: serverName, port: UInt16(port))
                self?.onDiscovered?(ip, UInt16(port))
            }
        }
    }
}
