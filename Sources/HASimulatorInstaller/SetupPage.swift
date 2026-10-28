import SwiftUI

struct SetupPage: View {
    let model: InstallerModel
    let updater: Updater

    var body: some View {
        Form {
            UpdateBanner(updater: updater)
            SetupSection(model: model)
            Section("Android") {
                AndroidSetupRow(android: model.android)
            }
            Section {
                Text("Xcode and an iOS Simulator are only needed for the iOS app, and the Android emulator for the Android app. GitHub is needed for test builds of both apps and the frontend. Core needs nothing: its first run downloads what it needs.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            if let errorMessage = model.errorMessage {
                Section {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .textSelection(.enabled)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Setup")
    }
}

#Preview {
    SetupPage(model: InstallerModel(), updater: Updater())
        .frame(width: 700, height: 500)
}
