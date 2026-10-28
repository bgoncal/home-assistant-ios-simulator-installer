import SwiftUI

struct ServerStatusView: View {
    let model: InstallerModel
    let running: RunningServer

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Label("Home Assistant is running", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text(running.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }

            AddressRow(title: "On this Mac and in the Simulator", url: running.localURL)
            if let networkURL = running.networkURL {
                AddressRow(title: "From a phone or another computer on the same network", url: networkURL)
            }

            HStack {
                Button("Show Log") { model.server.showLog() }
                if model.canConnectAppToServer {
                    Button("Connect the App to This Server") { Task { await model.connectAppToServer() } }
                }
            }
        }
    }
}

#Preview {
    ServerStatusView(
        model: InstallerModel(),
        running: RunningServer(
            port: 8123,
            networkAddress: "192.168.1.20",
            coreTitle: "2026.10.4",
            frontendTitle: "20260930.5",
            coreKey: "release-2026.10.4",
            frontendKey: "release-20260930.5",
            frontendDirectory: nil
        )
    )
    .padding()
    .frame(width: 700)
}
