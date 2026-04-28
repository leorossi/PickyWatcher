import SwiftUI

struct EmptyStateView: View {
    @Bindable var vm: ContentViewModel
    var onOpenFile: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.12))
                    .frame(width: 88, height: 88)
                Image(systemName: "eye.fill")
                    .font(.system(size: 38, weight: .ultraLight))
                    .foregroundStyle(Color.accentColor)
            }
            .padding(.bottom, 16)

            Text("PickyWatcher")
                .font(.title2.weight(.bold))

            Text("Filter and export M3U / M3U8 playlist streams")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 4)
                .padding(.bottom, 32)

            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Download from URL", systemImage: "arrow.down.to.line")
                        .font(.subheadline.weight(.medium))

                    HStack(spacing: 8) {
                        TextField("https://example.com/playlist.m3u8", text: $vm.downloadURLString)
                            .textFieldStyle(.roundedBorder)

                        Button {
                            vm.download(from: vm.downloadURLString)
                        } label: {
                            Label("Download", systemImage: "arrow.down.circle.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(vm.downloadURLString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                .padding(6)
            }
            .frame(maxWidth: 520)

            HStack {
                VStack { Divider() }
                Text("or").font(.caption).foregroundStyle(.tertiary).fixedSize()
                VStack { Divider() }
            }
            .frame(maxWidth: 260)
            .padding(.vertical, 20)

            Button(action: onOpenFile) {
                Label("Open File…", systemImage: "folder")
            }
            .keyboardShortcut("o")
            .buttonStyle(.bordered)
            .controlSize(.regular)

            Spacer()
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
