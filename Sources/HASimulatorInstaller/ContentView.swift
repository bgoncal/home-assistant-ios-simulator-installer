import SwiftUI

struct ContentView: View {
    @Bindable var model: InstallerModel
    let updater: Updater

    var body: some View {
        Form {
            UpdateBanner(updater: updater)
            SetupSection(model: model)
            if model.isReady {
                BuildSection(model: model)
                InstallSection(model: model)
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
        .frame(width: 620)
        .frame(minHeight: 420)
        .task { await model.refreshSetup() }
        .task { await updater.check(userInitiated: false) }
        .sheet(item: $model.deviceCode) { code in
            SignInSheet(model: model, code: code)
        }
        .sheet(isPresented: $model.showsTokenEntry) {
            TokenEntrySheet(model: model)
        }
        .sheet(isPresented: $model.showsXcodeVersions) {
            XcodeVersionsSheet(model: model)
        }
        .sheet(isPresented: $model.showsRuntimeVersions) {
            RuntimeVersionsSheet(model: model)
        }
    }
}

#Preview {
    ContentView(model: InstallerModel(), updater: Updater())
}
