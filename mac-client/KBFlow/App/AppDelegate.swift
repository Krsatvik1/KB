import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Request Accessibility permission
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String : true]
        AXIsProcessTrustedWithOptions(options)
        
        // Force dark mode for premium aesthetic
        NSApp.appearance = NSAppearance(named: .darkAqua)
        
        // Disable window restoration
        NSApp.disableRelaunchOnLogin()
    }
    
    func applicationDidBecomeActive(_ notification: Notification) {
        updatePresentationOptions()
    }
    
    func applicationWillUpdate(_ notification: Notification) {
        // Ensure main window is titled properly if it exists
        if let window = NSApp.windows.first {
            window.title = "FlowDesk"
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.isMovableByWindowBackground = true
            
            if !AppState.shared.isConnected {
                window.setContentSize(NSSize(width: 460, height: 520))
                window.styleMask.remove(.resizable)
            } else {
                window.styleMask.insert(.resizable) // Allow system to handle fullscreen transition
            }
        }
    }
    
    func updatePresentationOptions() {
        if AppState.shared.isConnected {
            NSApp.presentationOptions = [.hideDock, .hideMenuBar, .disableProcessSwitching]
        } else {
            NSApp.presentationOptions = []
        }
    }
}
