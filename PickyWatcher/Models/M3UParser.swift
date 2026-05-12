import Foundation

enum M3UParser {
    static func parse(url: URL) throws -> [M3UEntry] {
        let raw = try String(contentsOf: url, encoding: .utf8)
        return parse(string: raw)
    }

    static func parse(string: String) -> [M3UEntry] {
        var entries: [M3UEntry] = []
        let lines = string.components(separatedBy: .newlines)
        var pendingExtInf: String?

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("#EXTINF") {
                pendingExtInf = trimmed
            } else if !trimmed.isEmpty, !trimmed.hasPrefix("#"), let inf = pendingExtInf {
                entries.append(M3UEntry(extInf: inf, url: trimmed))
                pendingExtInf = nil
            }
        }
        return entries
    }

    static func serialize(header: String?, entries: [M3UEntry]) -> String {
        var lines: [String] = [header ?? "#EXTM3U"]
        for entry in entries {
            lines.append(entry.extInf)
            lines.append(entry.url)
        }
        return lines.joined(separator: "\n") + "\n"
    }
}
