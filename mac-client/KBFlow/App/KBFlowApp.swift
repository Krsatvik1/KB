import SwiftUI

@main
struct KBFlowApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .windowStyle(.hiddenTitleBar)
    }
}

// A simple root view router. We'll implement ConnectView and FullScreenView later.
struct RootView: View {
    @StateObject private var appState = AppState.shared
    
    var body: some View {
        if appState.isConnected {
            FullScreenView()
        } else {
            ConnectView()
        }
    }
}

class AppState: ObservableObject {
    static let shared = AppState()
    
    @Published var isConnected = false
    @Published var latencyMs = 0
}
