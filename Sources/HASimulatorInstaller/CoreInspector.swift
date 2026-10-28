import SwiftUI

struct CoreInspector: View {
    let model: InstallerModel
    @State private var tail = LogTail()
    @State private var showsServerLog = true
    @State private var confirmsErase = false

    var body: some View {
        @Bindable var server = model.server
        Form {
            InspectorStatusSection(status: model.status(of: .core))

            Section("Server") {
                LabeledContent("Version", value: server.running?.coreTitle ?? "Not running")
                LabeledContent("Name", value: ServerConfiguration.serverName)
                if let running = server.running {
                    LabeledContent("Address") {
                        Link(running.localURL.absoluteString, destination: running.localURL)
                    }
                    if let networkURL = running.networkURL {
                        LabeledContent("On your network") {
                            Link(networkURL.absoluteString, destination: networkURL)
                        }
                    }
                }
            }

            Section {
                TextField("Port", value: $server.preferredPort, format: .number.grouping(.never))
                Button("Show Data Folder") { server.revealConfigFolder() }
                Button("Erase Server Data…", role: .destructive) { confirmsErase = true }
                    .disabled(model.isBusy)
                    .confirmationDialog("Erase the server's data?", isPresented: $confirmsErase) {
                        Button("Erase", role: .destructive) { Task { await server.eraseData() } }
                    } message: {
                        Text("This stops the server and deletes its users, settings and history. The next run starts with onboarding.")
                    }
            } header: {
                Text("Settings")
            } footer: {
                Text("The port is used from the next run. When it's busy, the next free one is used.")
            }

            Section {
                Picker("Log", selection: $showsServerLog) {
                    Text("Server").tag(true)
                    Text("Installer").tag(false)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                if showsServerLog {
                    LogTextView(text: tail.text)
                    Button("Open in Console") { server.showLog() }
                } else {
                    ActivityLogView(entries: model.activityLog.entries(for: .core))
                }
            } header: {
                Text("Log")
            }
        }
        .formStyle(.grouped)
        .task { await tail.follow(Constants.serverLogFile) }
    }
}

#Preview {
    CoreInspector(model: InstallerModel())
        .frame(width: 360, height: 800)
}
