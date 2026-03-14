import Foundation

struct UpdateInfo {
    let version: String
    let url: URL
}

class Updater {
    static let shared = Updater()
    let currentVersion = "1.1.0"
    private let apiURL = URL(string: "https://api.github.com/repos/Krsatvik1/KB/releases/latest")!

    func checkForUpdates(completion: @escaping (UpdateInfo?) -> Void) {
        var req = URLRequest(url: apiURL)
        req.setValue("FlowDesk-Mac", forHTTPHeaderField: "User-Agent")
        URLSession.shared.dataTask(with: req) { [weak self] data, _, _ in
            guard let self,
                  let data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let tag = json["tag_name"] as? String,
                  let urlStr = json["html_url"] as? String,
                  let url = URL(string: urlStr)
            else { completion(nil); return }
            let latest = tag.trimmingCharacters(in: .init(charactersIn: "v"))
            if self.isNewer(latest, than: self.currentVersion) {
                completion(UpdateInfo(version: latest, url: url))
            } else {
                completion(nil)
            }
        }.resume()
    }

    private func isNewer(_ a: String, than b: String) -> Bool {
        let pa = a.split(separator: ".").compactMap { Int($0) }
        let pb = b.split(separator: ".").compactMap { Int($0) }
        for i in 0..<max(pa.count, pb.count) {
            let va = i < pa.count ? pa[i] : 0
            let vb = i < pb.count ? pb[i] : 0
            if va != vb { return va > vb }
        }
        return false
    }
}
