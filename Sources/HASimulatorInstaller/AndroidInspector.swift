import SwiftUI

struct AndroidInspector: View {
    let model: InstallerModel
    @State private var confirmsRemoval = false

    var body: some View {
        let android = model.android
        Form {
            InspectorStatusSection(status: model.status(of: .androidApp))

            Section("App") {
                if let build = android.installedBuild {
                    LabeledContent("Build", value: build.title)
                    LabeledContent("Commit", value: build.commit)
                    LabeledContent("Built", value: build.builtAt.formatted(.relative(presentation: .named)))
                } else {
                    LabeledContent("Build", value: "Not installed yet")
                }
                if let installedPackage = android.installedPackage {
                    LabeledContent("Package") {
                        Text(installedPackage).textSelection(.enabled)
                    }
                }
                if let device = android.device {
                    LabeledContent("Emulator", value: device.displayName)
                }
                if let sdk = android.sdk {
                    LabeledContent("Android SDK") {
                        Text(sdk.root.path)
                            .textSelection(.enabled)
                            .lineLimit(2)
                            .truncationMode(.middle)
                    }
                }
            }

            Section("Actions") {
                Button("Download APK") { model.downloadAPK() }
                    .disabled(!model.isSignedIn || model.isBusy)
                if android.isRunning {
                    Button("Take Screenshot") { Task { await model.takeAndroidScreenshot() } }
                    if model.canConnectAndroidToServer {
                        Button("Connect the App to This Server") { Task { await model.connectAndroidToServer() } }
                    }
                    Button("Remove App from Emulator…", role: .destructive) { confirmsRemoval = true }
                        .disabled(model.isBusy)
                        .confirmationDialog("Remove the app from the emulator?", isPresented: $confirmsRemoval) {
                            Button("Remove", role: .destructive) { Task { await android.removeApp() } }
                        } message: {
                            Text("Its servers, settings and data in the emulator are deleted too.")
                        }
                }
            }

            Section("Log") {
                ActivityLogView(entries: model.activityLog.entries(for: .androidApp))
            }
        }
        .formStyle(.grouped)
    }
}

#Preview {
    AndroidInspector(model: InstallerModel())
        .frame(width: 360, height: 700)
}
