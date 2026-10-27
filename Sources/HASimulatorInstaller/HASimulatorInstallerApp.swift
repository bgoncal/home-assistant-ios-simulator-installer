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
        Window("Home Assistant iOS Simulator Installer", id: "main") {
            ContentView(model: model, updater: updater)
        }
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Check for Updates…") {
                    Task { await updater.check(userInitiated: true) }
                }
            }
        }
    }
}
