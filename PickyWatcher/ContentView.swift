import SwiftUI
import UniformTypeIdentifiers

enum AppTab { case streams, groups }

struct ContentView: View {
    @State private var vm = ContentViewModel()
    @State private var showFilePicker = false
    @State private var showExportPicker = false
    @State private var activeTab: AppTab = .streams

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
                    progressText: vm.downloadProgressText
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
                        onToggle: { id, additive in vm.toggleSelection(id, additive: additive) }
                    )
                case .groups:
                    GroupsView(
                        groups: vm.filteredGroups,
                        selectedGroupName: vm.selectedGroupName,
                        onSelect: { vm.selectGroup($0) }
                    )
                }
            }
            if let err = vm.errorMessage {
                ErrorBarView(message: err, onDismiss: { vm.errorMessage = nil })
            }
        }
        .frame(minWidth: 620, minHeight: 500)
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
