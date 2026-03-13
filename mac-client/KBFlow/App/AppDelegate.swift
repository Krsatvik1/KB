import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Request Accessibility permission on first launch
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String : true]
        let accessibilityEnabled = AXIsProcessTrustedWithOptions(options)
        
        if !accessibilityEnabled {
            print("Please grant accessibility permissions and restart the app.")
        }
    }
    
    // Hide menu bar and dock while app is frontmost
    func applicationDidBecomeActive(_ notification: Notification) {
        if AppState.shared.isConnected {
            NSApp.presentationOptions = [.hideDock, .hideMenuBar, .disableForceQuit]
        }
    }
    
    func applicationDidResignActive(_ notification: Notification) {
        NSApp.presentationOptions = []
    }
}
