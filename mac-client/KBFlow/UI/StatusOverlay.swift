import SwiftUI

struct StatusOverlay: View {
    @StateObject private var appState = AppState.shared
    @State private var isVisible = true
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(appState.isConnected ? Color.green : Color.red)
                .frame(width: 8, height: 8)
            
            if appState.isConnected {
                Text("Connected  \(appState.latencyMs)ms")
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)
            } else {
                Text("Disconnected")
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.6))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .opacity(isVisible ? 1 : 0)
        .animation(.easeOut(duration: 1.0), value: isVisible)
        .onReceive(appState.$latencyMs) { _ in
            showTemporarily()
        }
        .onReceive(appState.$isConnected) { _ in
            showTemporarily()
        }
        .onAppear {
            showTemporarily()
        }
    }
    
    private func showTemporarily() {
        isVisible = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            // Only hide if we are still connected.
            if self.appState.isConnected {
                self.isVisible = false
            }
        }
    }
}
