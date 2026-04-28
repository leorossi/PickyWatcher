import SwiftUI

struct ContentToolbar: View {
    @Binding var activeTab: AppTab
    @Binding var showExportPicker: Bool
    @Bindable var vm: ContentViewModel

    var body: some View {
        HStack(spacing: 12) {
            if !vm.entries.isEmpty {
                Button { vm.close() } label: {
                    Label("Close", systemImage: "xmark.circle")
                }
                .buttonStyle(.bordered)

                Picker("", selection: $activeTab) {
                    Text("Streams").tag(AppTab.streams)
                    Text("Groups").tag(AppTab.groups)
                }
                .pickerStyle(.segmented)
                .frame(width: 160)

                switch activeTab {
                case .streams: streamsItems
                case .groups: groupsItems
                }
            }
        }
        .padding(10)
    }

    private var streamsItems: some View {
        HStack(spacing: 12) {
            SearchBar(
                query: $vm.searchQuery,
                isSearching: vm.isSearching,
                onCommit: { vm.commitSearch() },
                onClear: { vm.clearSearch() }
            )

            Spacer()

            countBadge(filtered: vm.filtered.count, total: vm.entries.count, label: "streams")

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

    private var groupsItems: some View {
        HStack(spacing: 12) {
            SearchBar(
                query: $vm.groupSearchQuery,
                placeholder: "Search groups",
                onCommit: { vm.commitGroupSearch() },
                onClear: { vm.clearGroupSearch() }
            )

            Spacer()

            countBadge(filtered: vm.filteredGroups.count, total: vm.groupedEntries.count, label: "groups")

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

    private func countBadge(filtered: Int, total: Int, label: String) -> some View {
        HStack(spacing: 3) {
            Text("\(filtered)")
                .fontWeight(.semibold)
                .monospacedDigit()
            Text("/ \(total) \(label)")
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .font(.callout)
    }
}
