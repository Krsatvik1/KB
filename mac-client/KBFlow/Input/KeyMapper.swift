import CoreGraphics

class KeyMapper {
    static let shared = KeyMapper()
    
    // Map macOS CGKeyCode to Windows Virtual Key (VK) codes
    let map: [CGKeyCode: Int] = [
        // Top row
        53: 0x1B, // Escape
        122: 0x70, // F1
        120: 0x71, // F2
        99: 0x72, // F3
        118: 0x73, // F4
        96: 0x74, // F5
        97: 0x75, // F6
        98: 0x76, // F7
        100: 0x77, // F8
        101: 0x78, // F9
        109: 0x79, // F10
        103: 0x7A, // F11
        111: 0x7B, // F12
        
        // Number row
        50: 0xC0, // ` (tilde)
        18: 0x31, // 1
        19: 0x32, // 2
        20: 0x33, // 3
        21: 0x34, // 4
        23: 0x35, // 5
        22: 0x36, // 6
        26: 0x37, // 7
        28: 0x38, // 8
        25: 0x39, // 9
        29: 0x30, // 0
        27: 0xBD, // -
        24: 0xBB, // =
        51: 0x08, // Delete/Backspace
        
        // QWERTY row
        48: 0x09, // Tab
        12: 0x51, // Q
        13: 0x57, // W
        14: 0x45, // E
        15: 0x52, // R
        17: 0x54, // T
        16: 0x59, // Y
        32: 0x55, // U
        34: 0x49, // I
        31: 0x4F, // O
        35: 0x50, // P
        33: 0xDB, // [
        30: 0xDD, // ]
        42: 0xDC, // \
        
        // ASDF row
        57: 0x14, // Caps Lock
        0: 0x41, // A
        1: 0x53, // S
        2: 0x44, // D
        3: 0x46, // F
        5: 0x47, // G
        4: 0x48, // H
        38: 0x4A, // J
        40: 0x4B, // K
        37: 0x4C, // L
        41: 0xBA, // ;
        39: 0xDE, // '
        36: 0x0D, // Return
        
        // ZXCV row
        56: 0xA0, // LShift
        6: 0x5A, // Z
        7: 0x58, // X
        8: 0x43, // C
        9: 0x56, // V
        11: 0x42, // B
        45: 0x4E, // N
        46: 0x4D, // M
        43: 0xBC, // ,
        47: 0xBE, // .
        44: 0xBF, // /
        60: 0xA1, // RShift
        
        // Modifiers / Bottom row
        59: 0xA2, // LCtrl
        58: 0x12, // LOption (Alt)
        55: 0x5B, // LCommand (Win)
        49: 0x20, // Space
        54: 0x5C, // RCommand (Win)
        61: 0xA5, // ROption (Alt)
        62: 0xA3, // RCtrl
        
        // Arrows
        123: 0x25, // Left
        126: 0x26, // Up
        124: 0x27, // Right
        125: 0x28  // Down
    ]
    
    func map(keyCode: CGKeyCode) -> Int? {
        return map[keyCode]
    }
}
