import CoreGraphics
import Foundation

class EventInterceptor {
    static let shared = EventInterceptor()
    private var tap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    
    // Panic escape state
    private var escPressCount = 0
    private var lastEscPressTime: Date?
    
    // Settings (mirrored from UserDefaults)
    private var cmdToWin: Bool { UserDefaults.standard.bool(forKey: "cmdToWin") }
    private var optToAlt: Bool { UserDefaults.standard.bool(forKey: "optToAlt") }
    private var fnPassthrough: Bool { UserDefaults.standard.bool(forKey: "fnPassthrough") }
    
    func start() {
        let mask1 = UInt64(1) << CGEventType.keyDown.rawValue
        let mask2 = UInt64(1) << CGEventType.keyUp.rawValue
        let mask3 = UInt64(1) << CGEventType.flagsChanged.rawValue
        let mask4 = UInt64(1) << CGEventType.mouseMoved.rawValue
        let mask5 = UInt64(1) << CGEventType.leftMouseDown.rawValue
        let mask6 = UInt64(1) << CGEventType.leftMouseUp.rawValue
        let mask7 = UInt64(1) << CGEventType.rightMouseDown.rawValue
        let mask8 = UInt64(1) << CGEventType.rightMouseUp.rawValue
        let mask9 = UInt64(1) << CGEventType.otherMouseDown.rawValue
        let mask10 = UInt64(1) << CGEventType.otherMouseUp.rawValue
        let mask11 = UInt64(1) << CGEventType.scrollWheel.rawValue
        
        let eventMask = CGEventMask(mask1 | mask2 | mask3 | mask4 | mask5 | mask6 | mask7 | mask8 | mask9 | mask10 | mask11)
        
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: { proxy, type, event, refcon in
                return EventInterceptor.shared.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: nil
        ) else {
            print("Failed to create event tap")
            return
        }
        
        self.tap = tap
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        self.runLoopSource = runLoopSource
        
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        print("Event tap started")
    }
    
    func stop() {
        if let tap = tap {
            CGEvent.tapEnable(tap: tap, enable: false)
            if let runLoopSource = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            }
            self.tap = nil
            self.runLoopSource = nil
        }
    }
    
    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        let ts = Int(Date().timeIntervalSince1970 * 1000)
        
        if type == .keyDown {
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            if keyCode == 53 { // Escape
                let now = Date()
                if let last = lastEscPressTime, now.timeIntervalSince(last) < 1.0 {
                    escPressCount += 1
                } else {
                    escPressCount = 1
                }
                lastEscPressTime = now
                
                if escPressCount >= 3 {
                    print("PANIC ESCAPE DETECTED")
                    triggerPanicEscape()
                    return Unmanaged.passUnretained(event)
                }
            } else {
                escPressCount = 0
            }
        }
        switch type {
        case .keyDown, .keyUp:
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            
            // Remap Command to Win if enabled
            var vk = KeyMapper.shared.map(keyCode: CGKeyCode(keyCode))
            if cmdToWin && (keyCode == 55 || keyCode == 54) {
                vk = (keyCode == 55) ? 0x5B : 0x5C // VK_LWIN / VK_RWIN
            }
            
            if let finalVk = vk {
                let flags = type == .keyDown ? 1 : 0
                let inputEvent = InputEvent(t: "k", vk: finalVk, flags: flags, ts: ts)
                ConnectionManager.shared.send(event: inputEvent)
            }
            return nil 
            
        case .flagsChanged:
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            let flags = event.flags
            
            var keymap: [CGKeyCode: (CGEventFlags, Int)] = [
                56: (.maskShift, 0xA0), // LShift
                60: (.maskShift, 0xA1), // RShift
                59: (.maskControl, 0xA2), // LCtrl
                62: (.maskControl, 0xA3), // RCtrl
                58: (.maskAlternate, 0x12), // LAlt
                61: (.maskAlternate, 0xA5), // RAlt
                55: (.maskCommand, 0x5B), // LWin
                54: (.maskCommand, 0x5C)  // RWin
            ]
            
            // Handle Option -> Alt remapping if enabled
            if optToAlt {
                // Already in keymap, but we can be explicit if needed
            }
            
            if let mapping = keymap[CGKeyCode(keyCode)] {
                let isPressed = flags.contains(mapping.0)
                let vk = mapping.1
                let flagsInt = isPressed ? 1 : 0
                let inputEvent = InputEvent(t: "k", vk: vk, flags: flagsInt, ts: ts)
                ConnectionManager.shared.send(event: inputEvent)
            }
            return nil
            
        case .mouseMoved:
            let dx = Int(event.getIntegerValueField(.mouseEventDeltaX))
            let dy = Int(event.getIntegerValueField(.mouseEventDeltaY))
            
            // Apply sensitivity slider
            let sensitivity = UserDefaults.standard.double(forKey: "mouseSensitivity")
            let adjDx = Int(Double(dx) * (sensitivity > 0 ? sensitivity : 1.0))
            let adjDy = Int(Double(dy) * (sensitivity > 0 ? sensitivity : 1.0))
            
            if adjDx != 0 || adjDy != 0 {
                let inputEvent = InputEvent(t: "m", dx: adjDx, dy: adjDy, ts: ts)
                ConnectionManager.shared.send(event: inputEvent)
            }
            return nil
            
        case .leftMouseDown, .leftMouseUp:
            let state = type == .leftMouseDown ? 1 : 0
            let inputEvent = InputEvent(t: "b", btn: 0, state: state, ts: ts)
            ConnectionManager.shared.send(event: inputEvent)
            return nil
            
        case .rightMouseDown, .rightMouseUp:
            let state = type == .rightMouseDown ? 1 : 0
            let inputEvent = InputEvent(t: "b", btn: 1, state: state, ts: ts)
            ConnectionManager.shared.send(event: inputEvent)
            return nil
            
        case .otherMouseDown, .otherMouseUp:
            let bn = event.getIntegerValueField(.mouseEventButtonNumber)
            if bn == 2 { // Middle mouse button
                let state = type == .otherMouseDown ? 1 : 0
                let inputEvent = InputEvent(t: "b", btn: 2, state: state, ts: ts)
                ConnectionManager.shared.send(event: inputEvent)
                return nil
            }
            return nil
            
        case .scrollWheel:
            let dx = Int(event.getIntegerValueField(.scrollWheelEventDeltaAxis2))
            let dy = Int(event.getIntegerValueField(.scrollWheelEventDeltaAxis1))
            
            if dx != 0 || dy != 0 {
                let inputEvent = InputEvent(t: "s", dx: dx, dy: dy, ts: ts)
                ConnectionManager.shared.send(event: inputEvent)
            }
            return nil
            
        default:
            return Unmanaged.passUnretained(event)
        }
    }
    
    func triggerPanicEscape() {
        stop()
        NotificationCenter.default.post(name: NSNotification.Name("flowdesk.releaseControl"), object: nil)
        print("Input control released")
    }
}
