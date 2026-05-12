import SwiftUI
import UniformTypeIdentifiers

enum AppTab { case streams, groups }

struct ContentView: View {
    @State private var vm = ContentViewModel()
    @State private var showFilePicker = false
    @State private var showExportPicker = false
    @State private var activeTab: AppTab = .streams
    @State private var copySuccessMessage: String? = nil
    @State private var copyDismissTask: Task<Void, Never>? = nil

    var body: some View {
        VStack(spacing: 0) {
            ContentToolbar(
                activeTab: $activeTab,
                showExportPicker: $showExportPicker,
                vm: vm
            )
            Divider()
            if vm.isDownloading {
                DownloadingView(
                    progress: vm.downloadProgress,
                    bytesTotal: vm.downloadBytesTotal,
                    progressText: vm.downloadProgressText,
                    onStop: { vm.cancelDownload() }
                )
            } else if vm.isIndexing {
                IndexingView(
                    progress: vm.indexingProgress,
                    indexedCount: vm.indexedCount,
                    total: vm.indexingTotal
                )
            } else if vm.entries.isEmpty {
                EmptyStateView(vm: vm, onOpenFile: { showFilePicker = true })
            } else {
                switch activeTab {
                case .streams:
                    EntryListView(
                        entries: vm.filtered,
                        selection: vm.selection,
                        onToggle: { id, additive in vm.toggleSelection(id, additive: additive) },
                        onShiftSelect: { from, to in vm.selectRange(from: from, to: to) },
                        onOpenVLC: { entry in vm.openInVLC(entry: entry) }
                    )
                case .groups:
                    GroupsView(
                        groups: vm.filteredGroups,
                        selectedGroupName: vm.selectedGroupName,
                        onSelect: { vm.selectGroup($0) }
                    )
                }
            }
        }
        .frame(minWidth: 620, minHeight: 500)
        .overlay(alignment: .bottom) {
            VStack(spacing: 8) {
                if let err = vm.errorMessage {
                    StatusToast(message: err, status: .error) { vm.errorMessage = nil }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                if let msg = copySuccessMessage {
                    StatusToast(message: msg, status: .success)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(.bottom, 16)
            .animation(.spring(response: 0.3, dampingFraction: 0.75), value: vm.errorMessage)
            .animation(.spring(response: 0.3, dampingFraction: 0.75), value: copySuccessMessage)
        }
        .background(
            CopyKeyHandler {
                guard activeTab == .streams, !vm.selection.isEmpty else { return }
                let count = vm.selection.count
                vm.copySelectedURLs()
                showCopySuccess(count: count)
            }
        )
        .onReceive(NotificationCenter.default.publisher(for: .openFileRequest)) { _ in
            showFilePicker = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .openRecentFileRequest)) { note in
            guard let path = note.object as? String else { return }
            if let url = vm.resolveRecentFile(path: path) {
                vm.load(from: url)
            } else {
                vm.errorMessage = "Could not access the file. Please open it again via File > Open."
            }
        }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.init(filenameExtension: "m3u8")!, .init(filenameExtension: "m3u")!],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                vm.load(from: url)
            }
        }
        .fileExporter(
            isPresented: $showExportPicker,
            document: M3UDocument(content: exportContent()),
            contentType: .init(filenameExtension: "m3u8")!,
            defaultFilename: exportFilename()
        ) { result in
            if case .failure(let err) = result {
                vm.errorMessage = err.localizedDescription
            }
        }
    }

    private func showCopySuccess(count: Int) {
        copyDismissTask?.cancel()
        withAnimation(.easeIn(duration: 0.15)) {
            copySuccessMessage = count == 1 ? "URL copied to clipboard" : "\(count) URLs copied to clipboard"
        }
        copyDismissTask = Task {
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.25)) { copySuccessMessage = nil }
            }
        }
    }

    private func exportContent() -> String {
        switch activeTab {
        case .streams:
            let toExport = vm.filtered.filter { vm.selection.contains($0.id) }
            return M3UParser.serialize(header: vm.fileHeader, entries: toExport)
        case .groups:
            guard let groupName = vm.selectedGroupName else { return "" }
            let toExport = vm.entries.filter { $0.group == groupName }
            return M3UParser.serialize(header: vm.fileHeader, entries: toExport)
        }
    }

    private func exportFilename() -> String {
        switch activeTab {
        case .streams: return "export.m3u8"
        case .groups:
            let name = vm.selectedGroupName ?? "group"
            let safe = name.isEmpty ? "no-group" : name.replacingOccurrences(of: "/", with: "-")
            return "\(safe).m3u8"
        }
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View { ContentView() }
}
#endif
