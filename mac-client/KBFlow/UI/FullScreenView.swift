import SwiftUI

struct FullScreenView: View {
    @State private var showInstruction = true
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color(hex: "0B0F1A")
                .ignoresSafeArea()
            
            StatusOverlay()
                .padding(20)
                
            if showInstruction {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "hand.tap.fill")
                        .font(.system(size: 40))
                        .foregroundColor(Color(hex: "00D4FF"))
                        .shadow(color: Color(hex: "00D4FF"), radius: 10)
                    
                    Text("Controlling Windows")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "E8EAF6"))
                    
                    VStack(spacing: 8) {
                        instructionRow(icon: "4.circle.fill", text: "Swipe up with 4 fingers to exit")
                        instructionRow(icon: "escape", text: "Press Esc × 3 quickly to panic-release")
                    }
                    .padding(24)
                    .background(Color(hex: "111827").opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(hex: "00D4FF").opacity(0.3), lineWidth: 1)
                    )
                    
                    Spacer()
                }
                .transition(.opacity)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        withAnimation { showInstruction = false }
                    }
                }
            }
        }
        .onAppear {
            EventInterceptor.shared.start()
            MouseTracker.shared.start()
            GestureHandler.shared.start()
            
            // Listen for panic release notification
            NotificationCenter.default.addObserver(forName: NSNotification.Name("flowdesk.releaseControl"), object: nil, queue: .main) { _ in
                AppState.shared.isConnected = false
            }
        }
        .onDisappear {
            EventInterceptor.shared.stop()
            MouseTracker.shared.stop()
            GestureHandler.shared.stop()
        }
    }
    
    private func instructionRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "00D4FF"))
            Text(text)
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "E8EAF6"))
        }
    }
}
