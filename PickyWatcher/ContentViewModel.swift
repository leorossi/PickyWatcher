import Foundation
import Observation

@Observable
final class ContentViewModel {
    var entries: [M3UEntry] = []
    var searchQuery: String = "" {
        didSet {
            debounceTask?.cancel()
            debounceTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(300))
                guard !Task.isCancelled else { return }
                debouncedSearchQuery = self.searchQuery
            }
        }
    }
    private(set) var debouncedSearchQuery: String = ""
    @ObservationIgnored private var debounceTask: Task<Void, Never>?
    var selection: Set<M3UEntry.ID> = []
    var fileHeader: String? = nil
    var loadedFileURL: URL? = nil
    var errorMessage: String? = nil

    var filtered: [M3UEntry] {
        guard !debouncedSearchQuery.isEmpty else { return entries }
        let q = debouncedSearchQuery.lowercased()
        return entries.filter {
            $0.name.lowercased().contains(q) ||
            $0.group.lowercased().contains(q) ||
            $0.url.lowercased().contains(q)
        }
    }

    var selectedCount: Int { selection.count }

    func load(from url: URL) {
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }
        do {
            // Preserve the #EXTM3U header line if present
            let raw = try String(contentsOf: url, encoding: .utf8)
            fileHeader = raw.components(separatedBy: .newlines).first(where: { $0.hasPrefix("#EXTM3U") })
            entries = M3UParser.parse(string: raw)
            selection = []
            searchQuery = ""
            debouncedSearchQuery = ""
            loadedFileURL = url
            errorMessage = nil
        } catch {
            errorMessage = "Failed to load file: \(error.localizedDescription)"
        }
    }

    func export(to url: URL) {
        let toExport = filtered.filter { selection.contains($0.id) }
        guard !toExport.isEmpty else { return }
        let content = M3UParser.serialize(header: fileHeader, entries: toExport)
        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
            errorMessage = nil
        } catch {
            errorMessage = "Failed to export: \(error.localizedDescription)"
        }
    }

    func selectAllFiltered() {
        filtered.forEach { selection.insert($0.id) }
    }

    func deselectAll() {
        selection = []
    }
}
