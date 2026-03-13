import SwiftUI

struct FullScreenView: View {
    @State private var showInstruction = true
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black
                .ignoresSafeArea()
            
            StatusOverlay()
                .padding(20)
                
            if showInstruction {
                VStack {
                    Spacer()
                    Text("Swipe up with 4 fingers to exit")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(12)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .transition(.opacity)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation {
                            showInstruction = false
                        }
                    }
                }
            }
        }
        .onAppear {
            EventInterceptor.shared.start()
            MouseTracker.shared.start()
            GestureHandler.shared.start()
        }
        .onDisappear {
            EventInterceptor.shared.stop()
            MouseTracker.shared.stop()
            GestureHandler.shared.stop()
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}
