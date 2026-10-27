import SwiftUI

struct SetupSection: View {
    let model: InstallerModel

    var body: some View {
        Section {
            SetupRow(
                title: "Xcode",
                detail: model.hasXcode ? "Provides the iOS Simulator" : "Free from the App Store. Only needed for the Simulator.",
                isDone: model.hasXcode
            ) {
                if model.xcodes.isEmpty {
                    Button("Get Xcode") { model.getXcodeFromAppStore() }
                } else {
                    Picker("Xcode", selection: Binding(
                        get: { model.selectedXcode },
                        set: { xcode in
                            if let xcode {
                                Task { await model.selectXcode(xcode) }
                            }
                        }
                    )) {
                        ForEach(model.xcodes) { xcode in
                            Text(xcode.displayName).tag(Optional(xcode))
                        }
                    }
                    .labelsHidden()
                    .fixedSize()
                    .disabled(model.activity != nil)
                }
                Button("Other Versions…") { model.showsXcodeVersions = true }
            }

            if let licenseMessage = model.licenseMessage {
                SetupRow(title: "Xcode license", detail: licenseMessage, isDone: false) {
                    Button("Open Xcode") { model.openSelectedXcode() }
                }
            }

            if model.hasXcode, model.licenseMessage == nil {
                SetupRow(
                    title: "iOS Simulator",
                    detail: model.hasSimulators
                        ? model.runtimes.map(model.runtimeLabel).joined(separator: ", ")
                        : "A one-time download of several gigabytes.",
                    isDone: model.hasSimulators
                ) {
                    Button(model.hasSimulators ? "Other Versions…" : "Download…") { model.showsRuntimeVersions = true }
                        .disabled(model.activity != nil)
                }
            }

            if let activity = model.activity {
                ActivityRow(activity: activity) { model.cancelActivity() }
            }

            SetupRow(
                title: "GitHub account",
                detail: accountDetail,
                isDone: model.isSignedIn
            ) {
                GitHubAccountMenu(model: model)
            }
        } header: {
            HStack {
                Text("Setup")
                Spacer()
                if model.isCheckingSetup {
                    ProgressView().controlSize(.small)
                } else if !model.isReady {
                    Button("Check Again") { Task { await model.refreshSetup() } }
                        .buttonStyle(.link)
                }
            }
        }
    }

    private var accountDetail: String {
        guard let username = model.username else { return "Needed to download test builds." }
        if case .gitHubCLI = model.credentialSource {
            return "Signed in as \(username) (from the GitHub CLI)"
        }
        return "Signed in as \(username)"
    }
}

#Preview {
    Form {
        SetupSection(model: InstallerModel())
    }
    .formStyle(.grouped)
}
