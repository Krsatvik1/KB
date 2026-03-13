import SwiftUI

struct ConnectView: View {
    @AppStorage("lastIPAddress") private var ipAddress: String = ""
    @AppStorage("lastPort") private var port: String = "5123"
    
    @StateObject private var connectionManager = ConnectionManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "keyboard")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("KBFlow")
                .font(.system(size: 24, weight: .bold))
            
            VStack(alignment: .leading) {
                Text("Windows PC IP Address")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("e.g. 192.168.1.100", text: $ipAddress)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 250)
            }
            
            VStack(alignment: .leading) {
                Text("Port")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("e.g. 5123", text: $port)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 250)
            }
            
            Button(action: {
                if let portInt = UInt16(port) {
                    connectionManager.connect(to: ipAddress, port: portInt)
                }
            }) {
                Text(connectionManager.isConnected ? "Connecting..." : "Connect")
                    .frame(width: 200)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .disabled(ipAddress.isEmpty || connectionManager.isConnected)
            
            if !connectionManager.isConnected && AppState.shared.latencyMs == -1 {
                Text("Connection refused or timed out.")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding(40)
        .frame(minWidth: 400, minHeight: 350)
    }
}
