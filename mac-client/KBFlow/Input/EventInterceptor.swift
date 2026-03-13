import CoreGraphics
import Foundation

class EventInterceptor {
    static let shared = EventInterceptor()
    private var tap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    
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
        
        switch type {
        case .keyDown, .keyUp:
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            if let vk = KeyMapper.shared.map(keyCode: CGKeyCode(keyCode)) {
                let flags = type == .keyDown ? 1 : 0
                let inputEvent = InputEvent(t: "k", vk: vk, flags: flags, ts: ts)
                ConnectionManager.shared.send(event: inputEvent)
            }
            return nil // Return nil to consume event so mac never sees it
            
        case .flagsChanged:
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            let flags = event.flags
            
            let keymap: [CGKeyCode: (CGEventFlags, Int)] = [
                56: (.maskShift, 0xA0),
                60: (.maskShift, 0xA1),
                59: (.maskControl, 0xA2),
                62: (.maskControl, 0xA3),
                58: (.maskAlternate, 0x12),
                61: (.maskAlternate, 0xA5),
                55: (.maskCommand, 0x5B),
                54: (.maskCommand, 0x5C)
            ]
            
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
            
            if dx != 0 || dy != 0 {
                let inputEvent = InputEvent(t: "m", dx: dx, dy: dy, ts: ts)
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
}
