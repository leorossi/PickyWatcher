import SwiftUI

private enum SettingsSection: Hashable { case general }

struct SettingsView: View {
    @State private var selectedSection: SettingsSection? = .general

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedSection) {
                Label("General", systemImage: "gearshape")
                    .tag(SettingsSection.general)
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(160)
        } detail: {
            switch selectedSection ?? .general {
            case .general: GeneralSettingsView()
            }
        }
        .frame(minWidth: 520, minHeight: 260)
    }
}
