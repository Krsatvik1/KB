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
    @StateObject private var appState = AppState.shared
    
    var body: some View {
        if appState.isConnected {
            FullScreenView()
        } else {
            ConnectView()
        }
    }
}
