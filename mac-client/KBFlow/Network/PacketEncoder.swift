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
        return prefixWithLength(jsonData)
    }
    
    static func encodeRaw(_ obj: [String: Any]) -> Data? {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: obj) else { return nil }
        return prefixWithLength(jsonData)
    }
    
    private static func prefixWithLength(_ data: Data) -> Data {
        var length = UInt16(data.count).bigEndian
        var packetData = Data(bytes: &length, count: MemoryLayout<UInt16>.size)
        packetData.append(data)
        return packetData
    }
}
