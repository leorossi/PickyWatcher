import SwiftUI

// MARK: - Notifications

extension Notification.Name {
    static let openFileRequest = Notification.Name("PickyWatcher.openFileRequest")
    static let openRecentFileRequest = Notification.Name("PickyWatcher.openRecentFileRequest")
}

// MARK: - Model

struct RecentFile: Codable {
    let displayName: String
    let path: String
    let bookmarkData: Data
}

// MARK: - Commands

struct AppFileCommands: Commands {
    @AppStorage("recentFiles") private var recentFilesData: Data = Data()

    private var recentFiles: [RecentFile] {
        (try? JSONDecoder().decode([RecentFile].self, from: recentFilesData)) ?? []
    }

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("Open…") {
                NotificationCenter.default.post(name: .openFileRequest, object: nil)
            }
            .keyboardShortcut("o")

            Menu("Open Recent") {
                ForEach(recentFiles, id: \.path) { file in
                    Button(file.displayName) {
                        NotificationCenter.default.post(name: .openRecentFileRequest, object: file.path)
                    }
                }
                if !recentFiles.isEmpty {
                    Divider()
                    Button("Clear Menu") {
                        UserDefaults.standard.removeObject(forKey: "recentFiles")
                    }
                }
            }
            .disabled(recentFiles.isEmpty)

            Divider()
        }
    }
}
