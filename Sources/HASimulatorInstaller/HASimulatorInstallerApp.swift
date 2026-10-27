import AppKit
import SwiftUI

@main
struct HASimulatorInstallerApp: App {
    @State private var model = InstallerModel()

    init() {
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate()
    }

    var body: some Scene {
        Window("Home Assistant iOS Simulator Installer", id: "main") {
            ContentView(model: model)
        }
        .windowResizability(.contentSize)
    }
}
