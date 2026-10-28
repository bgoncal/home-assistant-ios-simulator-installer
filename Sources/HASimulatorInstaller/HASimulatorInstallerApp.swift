import AppKit
import SwiftUI

@main
struct HASimulatorInstallerApp: App {
    @State private var model = InstallerModel()
    @State private var updater = Updater()

    init() {
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate()
    }

    var body: some Scene {
        Window("Home Assistant Test Lab", id: "main") {
            ContentView(model: model, updater: updater)
        }
        .defaultSize(width: 1440, height: 860)
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Check for Updates…") {
                    Task { await updater.check(userInitiated: true) }
                }
            }
            CommandGroup(replacing: .help) {
                Button("Welcome to Home Assistant Test Lab") { model.showsOnboarding = true }
            }
        }
    }
}
