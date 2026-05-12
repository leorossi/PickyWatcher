import SwiftUI

@main
struct PickyWatcherApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            AppFileCommands()
        }

        Settings {
            SettingsView()
        }
    }
}
