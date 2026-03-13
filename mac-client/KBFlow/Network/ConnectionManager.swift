import Foundation
import Network

class ConnectionManager: ObservableObject {
    static let shared = ConnectionManager()
    
    private var connection: NWConnection?
    private let queue = DispatchQueue(label: "com.kbflow.network")
    
    @Published var isConnected = false
    
    func connect(to ipAddress: String, port: UInt16 = 5123) {
        let host = NWEndpoint.Host(ipAddress)
        guard let nwPort = NWEndpoint.Port(rawValue: port) else {
            return
        }
        
        let tcpOptions = NWProtocolTCP.Options()
        tcpOptions.noDelay = true
        let params = NWParameters(tls: nil, tcp: tcpOptions)
        
        connection = NWConnection(host: host, port: nwPort, using: params)
        
        connection?.stateUpdateHandler = { [weak self] state in
            DispatchQueue.main.async {
                switch state {
                case .ready:
                    print("Connected")
                    self?.isConnected = true
                    AppState.shared.isConnected = true
                    LatencyProbe.shared.start()
                    self?.receiveData()
                case .failed(let error):
                    print("Connection failed: \(error)")
                    self?.handleDisconnect(ipAddress: ipAddress, port: port)
                case .waiting(let error):
                    print("Connection waiting: \(error)")
                    self?.handleDisconnect(ipAddress: ipAddress, port: port)
                case .cancelled:
                    print("Connection cancelled")
                    self?.isConnected = false
                    AppState.shared.isConnected = false
                    LatencyProbe.shared.stop()
                default:
                    break
                }
            }
        }
        
        connection?.start(queue: queue)
    }
    
    private func handleDisconnect(ipAddress: String, port: UInt16) {
        isConnected = false
        AppState.shared.isConnected = false
        LatencyProbe.shared.stop()
        reconnect(ipAddress: ipAddress, port: port)
    }
    
    private func reconnect(ipAddress: String, port: UInt16) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            if self?.isConnected == false {
                self?.connect(to: ipAddress, port: port)
            }
        }
    }
    
    func send(event: InputEvent) {
        guard let data = PacketEncoder.encode(event: event) else { return }
        
        connection?.send(content: data, completion: .contentProcessed({ error in
            if let error = error {
                print("Send error: \(error)")
            }
        }))
    }
    
    private func receiveData() {
        connection?.receive(minimumIncompleteLength: 2, maximumLength: 2) { [weak self] data, context, isComplete, error in
            if let data = data, data.count == 2 {
                let length = Int(data.withUnsafeBytes { $0.load(as: UInt16.self).bigEndian })
                self?.receivePayload(length: length)
            } else if let error = error {
                print("Receive error: \(error)")
                return
            } else if isComplete {
                print("Connection closed by server")
                return
            }
        }
    }
    
    private func receivePayload(length: Int) {
        connection?.receive(minimumIncompleteLength: length, maximumLength: length) { [weak self] data, context, isComplete, error in
            if let data = data {
                if let event = try? JSONDecoder().decode(InputEvent.self, from: data) {
                    if event.t == "pong", let ts = event.ts {
                        let now = Int(Date().timeIntervalSince1970 * 1000)
                        let rtt = now - ts
                        DispatchQueue.main.async {
                            AppState.shared.latencyMs = rtt / 2
                        }
                    }
                }
            }
            // Listen for next packet
            self?.receiveData()
        }
    }
}
