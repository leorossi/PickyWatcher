import SwiftUI

struct EmptyStateView: View {
    @Bindable var vm: ContentViewModel
    var onOpenFile: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Open an M3U / M3U8 playlist to get started")
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                Text("Download from URL")
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 8) {
                    TextField("https://example.com/playlist.m3u8", text: $vm.downloadURLString)
                        .textFieldStyle(.roundedBorder)

                    Button("Download") {
                        vm.download(from: vm.downloadURLString)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(vm.downloadURLString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .frame(maxWidth: 520)

            HStack(spacing: 8) {
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(.quaternary)
                Text("or")
                    .foregroundStyle(.tertiary)
                    .font(.caption)
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(.quaternary)
            }
            .frame(maxWidth: 240)

            Button("Open File…", action: onOpenFile)
                .keyboardShortcut("o")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
