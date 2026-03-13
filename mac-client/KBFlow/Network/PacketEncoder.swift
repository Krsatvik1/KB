import Foundation

struct InputEvent: Codable {
    var t: String
    var vk: Int?
    var flags: Int?
    var dx: Int?
    var dy: Int?
    var btn: Int?
    var state: Int?
    var ts: Int?
}

class PacketEncoder {
    static func encode(event: InputEvent) -> Data? {
        guard let jsonData = try? JSONEncoder().encode(event) else { return nil }
        
        // 2-byte header with big-endian length
        var length = UInt16(jsonData.count).bigEndian
        var packetData = Data(bytes: &length, count: MemoryLayout<UInt16>.size)
        packetData.append(jsonData)
        
        return packetData
    }
}
