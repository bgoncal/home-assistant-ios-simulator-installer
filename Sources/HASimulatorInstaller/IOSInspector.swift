import SwiftUI

struct IOSInspector: View {
    let model: InstallerModel
    @State private var confirmsRemoval = false

    var body: some View {
        Form {
            InspectorStatusSection(status: model.status(of: .iOSApp))

            Section("App") {
                if let build = model.installedBuild {
                    LabeledContent("Build", value: build.title)
                    LabeledContent("Commit", value: build.commit)
                    LabeledContent("Built", value: build.builtAt.formatted(.relative(presentation: .named)))
                } else {
                    LabeledContent("Build", value: "Not installed yet")
                }
                if let device = model.installedDevice {
                    LabeledContent("Simulator", value: device.name)
                }
                if let bundleID = model.runningBundleID {
                    LabeledContent("Bundle ID") {
                        Text(bundleID).textSelection(.enabled)
                    }
                }
            }

            if model.installedDevice != nil {
                Section("Actions") {
                    Button("Take Screenshot") { Task { await model.takeScreenshot() } }
                    Button(model.isRecording ? "Stop Recording" : "Record Screen") { model.toggleRecording() }
                    if model.canConnectAppToServer {
                        Button("Connect the App to This Server") { Task { await model.connectAppToServer() } }
                    }
                    Button("Remove App from Simulator…", role: .destructive) { confirmsRemoval = true }
                        .disabled(model.runningBundleID == nil || model.isBusy)
                        .confirmationDialog("Remove the app from the simulator?", isPresented: $confirmsRemoval) {
                            Button("Remove", role: .destructive) { Task { await model.removeAppFromSimulator() } }
                        } message: {
                            Text("Its servers, settings and data in the simulator are deleted too.")
                        }
                }
            }

            Section("Log") {
                ActivityLogView(entries: model.activityLog.entries(for: .iOSApp))
            }
        }
        .formStyle(.grouped)
    }
}

#Preview {
    IOSInspector(model: InstallerModel())
        .frame(width: 360, height: 700)
}
