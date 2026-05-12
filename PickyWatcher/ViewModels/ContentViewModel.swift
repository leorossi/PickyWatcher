import Foundation
import AppKit
import Observation

@Observable
final class ContentViewModel {
    var entries: [M3UEntry] = []
    var searchQuery: String = ""
    private(set) var filtered: [M3UEntry] = []
    var isIndexing: Bool = false
    var indexingProgress: Double = 0.0
    var indexedCount: Int = 0
    var indexingTotal: Int = 0
    var isSearching: Bool = false
    @ObservationIgnored private var filterTask: Task<Void, Never>?
    @ObservationIgnored private let filterThreadCount = ProcessInfo.processInfo.activeProcessorCount
    var selection: Set<M3UEntry.ID> = []
    var fileHeader: String? = nil
    var loadedFileURL: URL? = nil
    var errorMessage: String? = nil

    var selectedCount: Int { selection.count }

    var selectedGroupName: String? = nil
    private(set) var groupedEntries: [(name: String, entries: [M3UEntry])] = []
    private(set) var filteredGroups: [(name: String, entries: [M3UEntry])] = []
    var groupSearchQuery: String = ""

    // MARK: - Services

    let downloader = DownloadService()
    @ObservationIgnored let recentFiles = RecentFilesManager()

    // MARK: - Download forwarding

    var downloadURLString: String {
        get { downloader.urlString }
        set { downloader.urlString = newValue }
    }
    var isDownloading: Bool { downloader.isDownloading }
    var downloadProgress: Double { downloader.progress }
    var downloadBytesTotal: Int64 { downloader.bytesTotal }
    var downloadProgressText: String { downloader.progressText }

    private var playerBundleID: String {
        UserDefaults.standard.string(forKey: "defaultPlayerBundleID") ?? "org.videolan.vlc"
    }

    // MARK: - Group support

    private static func buildGroupedEntries(_ entries: [M3UEntry]) -> [(name: String, entries: [M3UEntry])] {
        let dict = Dictionary(grouping: entries) { $0.group }
        return dict.sorted {
            if $0.key.isEmpty { return false }
            if $1.key.isEmpty { return true }
            return $0.key.localizedCaseInsensitiveCompare($1.key) == .orderedAscending
        }.map { (name: $0.key, entries: $0.value) }
    }

    func selectGroup(_ name: String) {
        selectedGroupName = selectedGroupName == name ? nil : name
    }

    func commitGroupSearch() {
        let q = groupSearchQuery.lowercased().trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { filteredGroups = groupedEntries; return }
        filteredGroups = groupedEntries.filter { $0.name.lowercased().contains(q) }
    }

    func clearGroupSearch() {
        groupSearchQuery = ""
        filteredGroups = groupedEntries
    }

    // MARK: - Search

    func commitSearch() {
        scheduleFilter(query: searchQuery)
    }

    func clearSearch() {
        searchQuery = ""
        filterTask?.cancel()
        isSearching = false
        filtered = entries
    }

    // MARK: - Selection

    func toggleSelection(_ id: M3UEntry.ID, additive: Bool) {
        if additive {
            if selection.contains(id) { selection.remove(id) } else { selection.insert(id) }
        } else {
            selection = selection == [id] ? [] : [id]
        }
    }

    func selectRange(from fromIndex: Int, to toIndex: Int) {
        let lower = min(fromIndex, toIndex)
        let upper = max(fromIndex, toIndex)
        guard lower >= 0, upper < filtered.count else { return }
        filtered[lower...upper].forEach { selection.insert($0.id) }
    }

    func selectAllFiltered() {
        filtered.forEach { selection.insert($0.id) }
    }

    func deselectAll() {
        selection = []
    }

    func copySelectedURLs() {
        let selected = filtered.filter { selection.contains($0.id) }
        guard !selected.isEmpty else { return }
        let text = selected.count == 1
            ? selected[0].url
            : M3UParser.serialize(header: fileHeader, entries: selected)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    // MARK: - Player

    func openInVLC(entry: M3UEntry) {
        PlayerService.open(entry: entry, bundleID: playerBundleID) { [weak self] msg in
            self?.errorMessage = msg
        }
    }

    func openSelectedInVLC() {
        let selected = filtered.filter { selection.contains($0.id) }
        PlayerService.openSelection(selected, header: fileHeader, bundleID: playerBundleID) { [weak self] msg in
            self?.errorMessage = msg
        }
    }

    // MARK: - Recent files

    func addRecentFile(_ url: URL) { recentFiles.add(url) }
    func resolveRecentFile(path: String) -> URL? { recentFiles.resolve(path: path) }

    // MARK: - Close

    func close() { clearLoadedContent() }

    // MARK: - Load from file

    private func clearLoadedContent() {
        entries = []
        filtered = []
        selection = []
        selectedGroupName = nil
        groupedEntries = []
        filteredGroups = []
        groupSearchQuery = ""
        searchQuery = ""
        fileHeader = nil
        errorMessage = nil
        loadedFileURL = nil
    }

    func load(from url: URL) {
        let accessed = url.startAccessingSecurityScopedResource()
        isIndexing = true
        indexingProgress = 0.0
        indexedCount = 0
        indexingTotal = 0
        clearLoadedContent()

        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            do {
                let raw = try String(contentsOf: url, encoding: .utf8)
                await MainActor.run {
                    self.loadedFileURL = url
                    self.recentFiles.add(url)
                }
                if accessed { url.stopAccessingSecurityScopedResource() }
                await self.parseAndIndex(raw: raw)
            } catch {
                if accessed { url.stopAccessingSecurityScopedResource() }
                await MainActor.run {
                    self.errorMessage = "Failed to load file: \(error.localizedDescription)"
                    self.isIndexing = false
                }
            }
        }
    }

    // MARK: - Download

    func cancelDownload() {
        downloader.cancel()
        clearLoadedContent()
    }

    func download(from urlString: String) {
        downloader.urlString = urlString
        clearLoadedContent()
        downloader.start(
            onContent: { [weak self] raw in
                guard let self else { return }
                await MainActor.run {
                    self.isIndexing = true
                    self.indexingProgress = 0.0
                    self.indexedCount = 0
                    self.indexingTotal = 0
                }
                await self.parseAndIndex(raw: raw)
            },
            onError: { [weak self] msg in
                self?.errorMessage = msg
            }
        )
    }

    // MARK: - Parse

    private func parseAndIndex(raw: String) async {
        let lines = raw.components(separatedBy: .newlines).filter { !$0.isEmpty }
        let total = max(1, (lines.count - 2) / 2)
        let header = lines.first(where: { $0.hasPrefix("#EXTM3U") })

        await MainActor.run { self.indexingTotal = total }

        var parsedEntries: [M3UEntry] = []
        parsedEntries.reserveCapacity(total)
        var pendingExtInf: String?
        var count = 0

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("#EXTINF") {
                pendingExtInf = trimmed
            } else if !trimmed.isEmpty, !trimmed.hasPrefix("#"), let inf = pendingExtInf {
                parsedEntries.append(M3UEntry(extInf: inf, url: trimmed))
                pendingExtInf = nil
                count += 1
                if count % 500 == 0 {
                    let progress = Double(count) / Double(total)
                    await MainActor.run { [count] in
                        self.indexingProgress = min(progress, 0.99)
                        self.indexedCount = count
                    }
                }
            }
        }

        let grouped = Self.buildGroupedEntries(parsedEntries)

        await MainActor.run { [parsedEntries] in
            self.fileHeader = header
            self.entries = parsedEntries
            self.filtered = parsedEntries
            self.groupedEntries = grouped
            self.filteredGroups = grouped
            self.indexedCount = parsedEntries.count
            self.indexingProgress = 1.0
            self.isIndexing = false
        }
    }

    // MARK: - Export

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

    // MARK: - Filter

    private func scheduleFilter(query: String) {
        filterTask?.cancel()
        isSearching = true
        let allEntries = entries

        filterTask = Task {
            guard !query.isEmpty else {
                await MainActor.run {
                    self.filtered = allEntries
                    self.isSearching = false
                }
                return
            }

            let q = query.lowercased()
            let chunkSize = max(1, (allEntries.count + filterThreadCount - 1) / filterThreadCount)
            let chunks: [[M3UEntry]] = stride(from: 0, to: allEntries.count, by: chunkSize).map { start in
                Array(allEntries[start..<min(start + chunkSize, allEntries.count)])
            }

            let results = await withTaskGroup(of: (Int, [M3UEntry]).self) { group in
                for (index, chunk) in chunks.enumerated() {
                    group.addTask { (index, chunk.filter { $0.searchIndex.contains(q) }) }
                }
                var combined: [(Int, [M3UEntry])] = []
                for await partial in group { combined.append(partial) }
                return combined.sorted { $0.0 < $1.0 }.flatMap { $0.1 }
            }

            guard !Task.isCancelled else { return }
            await MainActor.run {
                self.filtered = results
                self.isSearching = false
            }
        }
    }
}
