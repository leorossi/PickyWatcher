import AppKit

enum PlayerService {
    static func name(for bundleID: String) -> String {
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            return bundleID.components(separatedBy: ".").last?.capitalized ?? "Player"
        }
        let b = Bundle(url: appURL)
        return b?.infoDictionary?["CFBundleDisplayName"] as? String
            ?? b?.infoDictionary?["CFBundleName"] as? String
            ?? appURL.deletingPathExtension().lastPathComponent
    }

    static func open(
        entry: M3UEntry,
        bundleID: String,
        onError: @escaping @MainActor (String) -> Void
    ) {
        guard let url = URL(string: entry.url) else {
            Task { @MainActor in onError("Invalid stream URL") }
            return
        }
        guard let playerURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            Task { @MainActor in onError("\(name(for: bundleID)) is not installed") }
            return
        }
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        NSWorkspace.shared.open([url], withApplicationAt: playerURL, configuration: config) { _, error in
            if let error {
                Task { @MainActor in onError("Failed to open player: \(error.localizedDescription)") }
            }
        }
    }

    static func openSelection(
        _ entries: [M3UEntry],
        header: String?,
        bundleID: String,
        onError: @escaping @MainActor (String) -> Void
    ) {
        guard !entries.isEmpty else { return }
        guard let playerURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            Task { @MainActor in onError("\(name(for: bundleID)) is not installed") }
            return
        }
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true

        if entries.count == 1, let url = URL(string: entries[0].url) {
            NSWorkspace.shared.open([url], withApplicationAt: playerURL, configuration: config) { _, error in
                if let error {
                    Task { @MainActor in onError("Failed to open player: \(error.localizedDescription)") }
                }
            }
        } else {
            let content = M3UParser.serialize(header: header, entries: entries)
            let tmpURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("pickywatcher_playlist.m3u8")
            do {
                try content.write(to: tmpURL, atomically: true, encoding: .utf8)
                NSWorkspace.shared.open([tmpURL], withApplicationAt: playerURL, configuration: config) { _, error in
                    if let error {
                        Task { @MainActor in onError("Failed to open player: \(error.localizedDescription)") }
                    }
                }
            } catch {
                Task { @MainActor in onError("Failed to create temp playlist: \(error.localizedDescription)") }
            }
        }
    }
}
