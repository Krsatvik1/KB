import SwiftUI

struct StatusOverlay: View {
    @ObservedObject private var appState = AppState.shared
    @State private var isVisible = true
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(appState.isConnected ? Color(hex: "00D4FF") : Color(hex: "FF4566"))
                .frame(width: 8, height: 8)
                .shadow(color: appState.isConnected ? Color(hex: "00D4FF") : .clear, radius: 4)
            
            if appState.isConnected {
                Text("Connected  \(appState.latencyMs)ms")
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(hex: "E8EAF6"))
            } else {
                Text("Disconnected")
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(hex: "E8EAF6"))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color(hex: "0B0F1A").opacity(0.85))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color(hex: "00D4FF").opacity(0.2), lineWidth: 1)
        )
        .opacity(isVisible ? 1 : 0)
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
        withAnimation(.easeIn(duration: 0.2)) { isVisible = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            if self.appState.isConnected {
                withAnimation(.easeOut(duration: 1.0)) { self.isVisible = false }
            }
        }
    }
}
