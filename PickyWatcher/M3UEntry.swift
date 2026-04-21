import Foundation

struct M3UEntry: Identifiable, Hashable {
    let id = UUID()
    let extInf: String   // full #EXTINF line
    let url: String      // stream URL

    var name: String {
        // last comma-separated segment is the display name
        extInf.components(separatedBy: ",").last?.trimmingCharacters(in: .whitespaces) ?? url
    }

    var group: String {
        guard let range = extInf.range(of: #"group-title="([^"]*)"#, options: .regularExpression) else {
            return ""
        }
        let match = String(extInf[range])
        return match
            .replacingOccurrences(of: "group-title=\"", with: "")
            .replacingOccurrences(of: "\"", with: "")
    }
}
