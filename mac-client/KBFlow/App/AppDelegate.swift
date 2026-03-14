import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Force dark mode for premium aesthetic
        NSApp.appearance = NSAppearance(named: .darkAqua)
        
        // Disable window restoration
        NSApp.disableRelaunchOnLogin()
        
        // Initial window setup
        if let window = NSApp.windows.first {
            window.title = "FlowDesk"
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.isMovableByWindowBackground = true
            window.setContentSize(NSSize(width: 460, height: 520))
        }
    }
    
    func applicationDidBecomeActive(_ notification: Notification) {
        updatePresentationOptions()
    }
    
    func updatePresentationOptions() {
        if AppState.shared.isConnected {
            NSApp.presentationOptions = [.hideDock, .hideMenuBar, .disableProcessSwitching]
        } else {
            NSApp.presentationOptions = []
        }
    }
    
    func toggleFullScreen(_ enable: Bool) {
        guard let window = NSApp.windows.first else { return }
        let isFullScreen = window.styleMask.contains(.fullScreen)
        
        if enable && !isFullScreen {
            window.toggleFullScreen(nil)
        } else if !enable && isFullScreen {
            window.toggleFullScreen(nil)
            // Restore size after exit
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                window.setContentSize(NSSize(width: 460, height: 520))
                window.center()
            }
        }
    }
}
