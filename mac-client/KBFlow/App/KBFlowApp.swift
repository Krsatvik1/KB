import SwiftUI

@main
struct FlowDeskApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .windowStyle(.hiddenTitleBar)
    }
}

struct RootView: View {
    @ObservedObject private var appState = AppState.shared
    
    var body: some View {
        ZStack {
            if appState.isConnected {
                FullScreenView()
                    .transition(.opacity)
            } else {
                ConnectView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.isConnected)
        .onChange(of: appState.isConnected) { oldValue, newValue in
            if let delegate = NSApp.delegate as? AppDelegate {
                delegate.toggleFullScreen(newValue)
            }
        }
    }
}
