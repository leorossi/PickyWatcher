import Foundation

struct M3UEntry: Identifiable, Hashable {
    let id = UUID()
    let extInf: String
    let url: String
    let name: String
    let group: String
    // pre-lowercased concatenation used by the search filter
    let searchIndex: String

    init(extInf: String, url: String) {
        self.extInf = extInf
        self.url = url

        let name = extInf.components(separatedBy: ",").last?
            .trimmingCharacters(in: .whitespaces) ?? url
        self.name = name

        var group = ""
        if let range = extInf.range(of: #"group-title="([^"]*)"#, options: .regularExpression) {
            let match = String(extInf[range])
            group = match
                .replacingOccurrences(of: "group-title=\"", with: "")
                .replacingOccurrences(of: "\"", with: "")
        }
        self.group = group

        self.searchIndex = "\(name)\n\(group)".lowercased()
    }
}
