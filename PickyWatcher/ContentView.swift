import SwiftUI

struct ContentView: View {
    @State private var vm = ContentViewModel()
    @State private var showFilePicker = false
    @State private var showExportPicker = false

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            if vm.entries.isEmpty {
                emptyState
            } else {
                entryList
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
            defaultFilename: "export.m3u8"
        ) { result in
            if case .failure(let err) = result {
                vm.errorMessage = err.localizedDescription
            }
        }
    }

    // MARK: - Subviews

    private var toolbar: some View {
        HStack(spacing: 12) {
            Button("Open…") { showFilePicker = true }
                .keyboardShortcut("o")

            if !vm.entries.isEmpty {
                TextField("Search", text: $vm.searchQuery)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 300)

                Spacer()

                Text("\(vm.filtered.count) / \(vm.entries.count) entries")
                    .foregroundStyle(.secondary)
                    .font(.callout)

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
        .padding(10)
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
        List(vm.filtered, selection: $vm.selection) { entry in
            EntryRow(entry: entry, isSelected: vm.selection.contains(entry.id))
        }
        .listStyle(.inset)
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

    private func exportContent() -> String {
        let toExport = vm.filtered.filter { vm.selection.contains($0.id) }
        return M3UParser.serialize(header: vm.fileHeader, entries: toExport)
    }
}

// MARK: - Entry Row

struct EntryRow: View {
    let entry: M3UEntry
    let isSelected: Bool

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
        .padding(.vertical, 2)
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
