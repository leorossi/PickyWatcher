import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct GeneralSettingsView: View {
    @AppStorage("defaultPlayerBundleID") private var playerBundleID = "org.videolan.vlc"

    private var playerURL: URL? {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: playerBundleID)
    }
    private var playerName: String { PlayerService.name(for: playerBundleID) }
    private var playerIcon: NSImage? {
        guard let url = playerURL else { return nil }
        return NSWorkspace.shared.icon(forFile: url.path)
    }

    var body: some View {
        Form {
            Section {
                LabeledContent("Media Player") {
                    HStack(spacing: 8) {
                        if let icon = playerIcon {
                            Image(nsImage: icon)
                                .resizable()
                                .interpolation(.high)
                                .frame(width: 20, height: 20)
                        }
                        Text(playerName)
                            .foregroundStyle(playerURL == nil ? .red : .primary)
                        Button("Change…") { chooseApp() }
                    }
                }
            } header: {
                Text("Default Player")
            } footer: {
                Text("Used when opening streams or playlists from the toolbar.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("General")
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func chooseApp() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.applicationBundle]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.title = "Choose Media Player"
        panel.prompt = "Select"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        if let id = Bundle(url: url)?.bundleIdentifier {
            playerBundleID = id
        }
    }
}
