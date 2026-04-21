import SwiftUI
import AppKit

enum AppTab { case streams, groups }

struct ContentView: View {
    @State private var vm = ContentViewModel()
    @State private var showFilePicker = false
    @State private var showExportPicker = false
    @State private var activeTab: AppTab = .streams

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            if vm.isIndexing {
                indexingView
            } else if vm.entries.isEmpty {
                emptyState
            } else {
                switch activeTab {
                case .streams: entryList
                case .groups:
                    GroupsView(
                        groups: vm.filteredGroups,
                        selectedGroupName: vm.selectedGroupName,
                        onSelect: { vm.selectGroup($0) }
                    )
                }
            }
            if let err = vm.errorMessage {
                errorBar(err)
            }
        }
        .frame(minWidth: 600, minHeight: 500)
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

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack(spacing: 12) {
            Button("Open…") { showFilePicker = true }
                .keyboardShortcut("o")

            if !vm.entries.isEmpty && !vm.isIndexing {
                Picker("", selection: $activeTab) {
                    Text("Streams").tag(AppTab.streams)
                    Text("Groups").tag(AppTab.groups)
                }
                .pickerStyle(.segmented)
                .frame(width: 160)

                switch activeTab {
                case .streams: streamsToolbarItems
                case .groups: groupsToolbarItems
                }
            }
        }
        .padding(10)
    }

    private var streamsToolbarItems: some View {
        HStack(spacing: 12) {
            SearchBar(
                query: $vm.searchQuery,
                isSearching: vm.isSearching,
                onCommit: { vm.commitSearch() },
                onClear: { vm.clearSearch() }
            )

            Spacer()

            Text("\(vm.filtered.count) / \(vm.entries.count) streams")
                .foregroundStyle(.secondary)
                .font(.callout)
                .monospacedDigit()

            Button("Select All") { vm.selectAllFiltered() }
                .disabled(vm.filtered.isEmpty)

            Button("Deselect All") { vm.deselectAll() }
                .disabled(vm.selection.isEmpty)

            Button("Export \(vm.selectedCount > 0 ? "(\(vm.selectedCount))" : "")…") {
                showExportPicker = true
            }
            .keyboardShortcut("s")
            .disabled(vm.selection.isEmpty)
            .buttonStyle(.borderedProminent)
        }
    }

    private var groupsToolbarItems: some View {
        HStack(spacing: 12) {
            SearchBar(
                query: $vm.groupSearchQuery,
                placeholder: "Search groups",
                onCommit: { vm.commitGroupSearch() },
                onClear: { vm.clearGroupSearch() }
            )

            Spacer()

            Text("\(vm.filteredGroups.count) / \(vm.groupedEntries.count) groups")
                .foregroundStyle(.secondary)
                .font(.callout)
                .monospacedDigit()

            if let groupName = vm.selectedGroupName {
                let count = vm.groupedEntries.first(where: { $0.name == groupName })?.entries.count ?? 0
                Button("Export \"\(groupName.isEmpty ? "No Group" : groupName)\" (\(count))…") {
                    showExportPicker = true
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button("Export Group…") { }
                    .disabled(true)
                    .buttonStyle(.borderedProminent)
            }
        }
    }

    // MARK: - Content views

    private var indexingView: some View {
        VStack(spacing: 16) {
            Text("Indexing…")
                .foregroundStyle(.secondary)
            ProgressView(value: vm.indexingProgress)
                .frame(maxWidth: 320)
            Text("\(vm.indexedCount) / \(vm.indexingTotal) streams")
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Open an M3U / M3U8 playlist to get started")
                .foregroundStyle(.secondary)
            Button("Open File…") { showFilePicker = true }
                .keyboardShortcut("o")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var entryList: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: []) {
                ForEach(vm.filtered) { entry in
                    EntryRow(entry: entry, isSelected: vm.selection.contains(entry.id))
                        .onTapGesture {
                            vm.toggleSelection(entry.id, additive: NSEvent.modifierFlags.contains(.command))
                        }
                    Divider()
                        .padding(.leading, 8)
                }
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
    }

    private func errorBar(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
            Text(message)
                .font(.callout)
            Spacer()
            Button("Dismiss") { vm.errorMessage = nil }
                .buttonStyle(.borderless)
        }
        .padding(8)
        .background(Color.red.opacity(0.1))
    }

    // MARK: - Export helpers

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
        case .streams:
            return "export.m3u8"
        case .groups:
            let name = vm.selectedGroupName ?? "group"
            let safe = name.isEmpty ? "no-group" : name.replacingOccurrences(of: "/", with: "-")
            return "\(safe).m3u8"
        }
    }
}

// MARK: - Entry Row

struct EntryRow: View {
    let entry: M3UEntry
    let isSelected: Bool
    @State private var isHovered = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.name)
                    .fontWeight(isSelected ? .semibold : .regular)
                if !entry.group.isEmpty {
                    Text(entry.group)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text(entry.url)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: 200)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            isSelected
                ? Color.accentColor.opacity(0.2)
                : isHovered ? Color(NSColor.selectedContentBackgroundColor).opacity(0.07) : Color.clear
        )
        .onHover { isHovered = $0 }
    }
}

// MARK: - FileDocument for export

import UniformTypeIdentifiers

struct M3UDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.init(filenameExtension: "m3u8")!, .init(filenameExtension: "m3u")!] }
    var content: String

    init(content: String) { self.content = content }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        content = String(decoding: data, as: UTF8.self)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(content.utf8))
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View { ContentView() }
}
#endif
