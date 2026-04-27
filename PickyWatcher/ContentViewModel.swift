import Foundation
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

    // MARK: - Download state

    var downloadURLString: String = UserDefaults.standard.string(forKey: "lastDownloadURL") ?? ""
    var isDownloading: Bool = false
    var downloadProgress: Double = 0.0
    var downloadBytesReceived: Int64 = 0
    var downloadBytesTotal: Int64 = 0

    var downloadProgressText: String {
        let fmt = ByteCountFormatter()
        fmt.countStyle = .file
        let received = fmt.string(fromByteCount: downloadBytesReceived)
        guard downloadBytesTotal > 0 else { return received }
        return "\(received) / \(fmt.string(fromByteCount: downloadBytesTotal))"
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
        guard !q.isEmpty else {
            filteredGroups = groupedEntries
            return
        }
        filteredGroups = groupedEntries.filter { $0.name.lowercased().contains(q) }
    }

    func clearGroupSearch() {
        groupSearchQuery = ""
        filteredGroups = groupedEntries
    }

    // MARK: - Search

    func commitSearch() {
        print("[Search] commitSearch called — query: '\(searchQuery)', entries: \(entries.count)")
        scheduleFilter(query: searchQuery)
    }

    func clearSearch() {
        searchQuery = ""
        filterTask?.cancel()
        isSearching = false
        filtered = entries
    }

    func toggleSelection(_ id: M3UEntry.ID, additive: Bool) {
        if additive {
            if selection.contains(id) { selection.remove(id) } else { selection.insert(id) }
        } else {
            selection = selection == [id] ? [] : [id]
        }
    }

    private func scheduleFilter(query: String) {
        print("[Search] scheduleFilter — cancelling previous task, query: '\(query)'")
        filterTask?.cancel()
        isSearching = true
        let allEntries = entries
        print("[Search] scheduleFilter — allEntries count: \(allEntries.count)")

        filterTask = Task {
            NSLog("[Search] task started on thread")
            guard !query.isEmpty else {
                print("[Search] empty query — restoring full list (\(allEntries.count) entries)")
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
            print("[Search] splitting into \(chunks.count) chunks of ~\(chunkSize) entries each")

            let results = await withTaskGroup(of: (Int, [M3UEntry]).self) { group in
                for (index, chunk) in chunks.enumerated() {
                    group.addTask {
                        print("[Search] chunk \(index) started — \(chunk.count) entries")
                        let partial = chunk.filter { $0.searchIndex.contains(q) }
                        print("[Search] chunk \(index) done — \(partial.count) matches")
                        return (index, partial)
                    }
                }
                var combined: [(Int, [M3UEntry])] = []
                for await partial in group { combined.append(partial) }
                return combined.sorted { $0.0 < $1.0 }.flatMap { $0.1 }
            }

            print("[Search] all chunks done — total results: \(results.count), cancelled: \(Task.isCancelled)")
            guard !Task.isCancelled else {
                print("[Search] task was cancelled, discarding results")
                return
            }
            print("[Search] updating filtered on MainActor")
            await MainActor.run {
                self.filtered = results
                self.isSearching = false
            }
            print("[Search] filtered updated successfully")
        }
    }

    // MARK: - Close

    func close() {
        clearLoadedContent()
    }

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
                if accessed { url.stopAccessingSecurityScopedResource() }
                await MainActor.run { self.loadedFileURL = url }
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

    // MARK: - Download from URL

    func download(from urlString: String) {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let url = URL(string: trimmed), url.scheme != nil else {
            errorMessage = "Invalid URL"
            return
        }

        UserDefaults.standard.set(trimmed, forKey: "lastDownloadURL")
        downloadURLString = trimmed
        isDownloading = true
        downloadProgress = 0.0
        downloadBytesReceived = 0
        downloadBytesTotal = 0
        clearLoadedContent()

        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            do {
                let (asyncBytes, response) = try await URLSession.shared.bytes(from: url)

                if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                    await MainActor.run {
                        self.errorMessage = "Server returned HTTP \(http.statusCode)"
                        self.isDownloading = false
                    }
                    return
                }

                let total = response.expectedContentLength
                await MainActor.run { self.downloadBytesTotal = total }

                var buffer = Data(capacity: total > 0 ? Int(min(total, 100_000_000)) : 50_000_000)
                for try await byte in asyncBytes {
                    buffer.append(byte)
                    if buffer.count % (1024 * 1024) == 0 {
                        let received = Int64(buffer.count)
                        let progress = total > 0 ? Double(received) / Double(total) : 0.0
                        Task { @MainActor [weak self] in
                            self?.downloadBytesReceived = received
                            self?.downloadProgress = progress
                        }
                    }
                }

                guard let raw = String(data: buffer, encoding: .utf8)
                        ?? String(data: buffer, encoding: .isoLatin1) else {
                    await MainActor.run {
                        self.errorMessage = "Downloaded file has unsupported encoding"
                        self.isDownloading = false
                    }
                    return
                }

                let finalSize = Int64(buffer.count)
                await MainActor.run {
                    self.downloadBytesReceived = finalSize
                    self.isDownloading = false
                    self.isIndexing = true
                    self.indexingProgress = 0.0
                    self.indexedCount = 0
                    self.indexingTotal = 0
                }

                await self.parseAndIndex(raw: raw)

            } catch {
                await MainActor.run {
                    self.errorMessage = "Download failed: \(error.localizedDescription)"
                    self.isDownloading = false
                }
            }
        }
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

    func selectAllFiltered() {
        filtered.forEach { selection.insert($0.id) }
    }

    func deselectAll() {
        selection = []
    }
}
