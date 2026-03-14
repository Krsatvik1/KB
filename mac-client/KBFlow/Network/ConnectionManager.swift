import Foundation
import Network
import AppKit

enum ConnectResult {
    case success
    case requiresPairing
    case failure(String)
}

class ConnectionManager: ObservableObject {
    static let shared = ConnectionManager()

    private var connection: NWConnection?
    private let queue = DispatchQueue(label: "flowdesk.network", qos: .userInitiated)
    private var lastHost: String = ""
    private var lastPort: UInt16 = 5123
    private var connectCompletion: ((ConnectResult) -> Void)?
    private var wakeObserver: Any?

    @Published var isConnected = false

    private init() {
        registerSleepWake()
    }

    // MARK: - Connect

    func connect(host: String, port: UInt16 = 5123, completion: @escaping (ConnectResult) -> Void) {
        lastHost = host
        lastPort = port
        connectCompletion = completion

        let tcpOpts = NWProtocolTCP.Options()
        tcpOpts.noDelay = true
        let params = NWParameters(tls: nil, tcp: tcpOpts)

        connection = NWConnection(
            host: NWEndpoint.Host(host),
            port: NWEndpoint.Port(rawValue: port)!,
            using: params
        )

        connection?.stateUpdateHandler = { [weak self] state in
            DispatchQueue.main.async {
                switch state {
                case .ready:
                    self?.isConnected = true
                    LatencyProbe.shared.start()
                    self?.receiveLoop()
                case .failed(let err):
                    self?.tearDown()
                    self?.connectCompletion?(.failure(err.localizedDescription))
                    self?.connectCompletion = nil
                    self?.scheduleAutoReconnect()
                case .cancelled:
                    self?.tearDown()
                default: break
                }
            }
        }
        connection?.start(queue: queue)
    }

    // Submit pairing PIN after auth_required is received
    func submitPairingPin(_ pin: String) {
        guard let data = PacketEncoder.encodeRaw(["t": "auth", "pin": pin]) else { return }
        sendRaw(data)
    }

    func disconnect() {
        wakeObserver = nil
        connection?.cancel()
        tearDown()
    }

    // MARK: - Send

    func send(event: InputEvent) {
        guard let data = PacketEncoder.encode(event: event) else { return }
        sendRaw(data)
    }

    private func sendRaw(_ data: Data) {
        connection?.send(content: data, completion: .contentProcessed({ _ in }))
    }

    // MARK: - Receive loop

    private func receiveLoop() {
        connection?.receive(minimumIncompleteLength: 2, maximumLength: 2) { [weak self] data, _, complete, error in
            guard let self, let data, data.count == 2 else {
                if error != nil || complete == true { self?.handleUnexpectedDrop() }
                return
            }
            let len = Int(data.withUnsafeBytes { $0.load(as: UInt16.self).bigEndian })
            self.receivePayload(length: len)
        }
    }

    private func receivePayload(length: Int) {
        connection?.receive(minimumIncompleteLength: length, maximumLength: length) { [weak self] data, _, complete, error in
            guard let self else { return }
            if let data, let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let t = json["t"] as? String
                if t == "pong", let ts = json["ts"] as? Int {
                    let rtt = Int(Date().timeIntervalSince1970 * 1000) - ts
                    DispatchQueue.main.async { LatencyProbe.shared.updateRTT(rtt) }
                } else if t == "auth_required" {
                    DispatchQueue.main.async {
                        self.connectCompletion?(.requiresPairing)
                        self.connectCompletion = nil
                    }
                } else if t == "auth_ok" {
                    DispatchQueue.main.async {
                        self.connectCompletion?(.success)
                        self.connectCompletion = nil
                    }
                } else if t == "auth_fail" {
                    DispatchQueue.main.async {
                        self.connectCompletion?(.failure("Incorrect PIN. Try again."))
                        self.connectCompletion = nil
                    }
                }
            }
            if error != nil || complete == true {
                self.handleUnexpectedDrop()
            } else {
                self.receiveLoop()
            }
        }
    }

    // MARK: - Drop handling

    private func handleUnexpectedDrop() {
        DispatchQueue.main.async {
            self.tearDown()
            // Trigger escape so user is never stuck
            EventInterceptor.shared.triggerPanicEscape()
            self.scheduleAutoReconnect()
        }
    }

    private func tearDown() {
        isConnected = false
        LatencyProbe.shared.stop()
    }

    private func scheduleAutoReconnect() {
        guard !lastHost.isEmpty else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            guard let self, !self.isConnected else { return }
            self.connect(host: self.lastHost, port: self.lastPort) { _ in }
        }
    }

    // MARK: - Sleep / Wake

    private func registerSleepWake() {
        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self, !self.lastHost.isEmpty, !self.isConnected else { return }
            print("Wake detected — reconnecting to \(self.lastHost)")
            self.connect(host: self.lastHost, port: self.lastPort) { _ in }
        }
    }
}
