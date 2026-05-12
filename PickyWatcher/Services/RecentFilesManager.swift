import Foundation

final class RecentFilesManager {
    private let key = "recentFiles"

    func add(_ url: URL) {
        guard let bookmarkData = try? url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: [.nameKey],
            relativeTo: nil
        ) else { return }
        let entry = RecentFile(displayName: url.lastPathComponent, path: url.path, bookmarkData: bookmarkData)
        var list = stored()
        list.removeAll { $0.path == url.path }
        list.insert(entry, at: 0)
        if list.count > 10 { list = Array(list.prefix(10)) }
        if let data = try? JSONEncoder().encode(list) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func resolve(path: String) -> URL? {
        guard let entry = stored().first(where: { $0.path == path }) else { return nil }
        var stale = false
        return try? URL(resolvingBookmarkData: entry.bookmarkData,
                        options: .withSecurityScope, relativeTo: nil,
                        bookmarkDataIsStale: &stale)
    }

    func stored() -> [RecentFile] {
        guard let data = UserDefaults.standard.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([RecentFile].self, from: data)) ?? []
    }
}
