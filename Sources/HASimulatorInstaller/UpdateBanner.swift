import SwiftUI

struct UpdateBanner: View {
    let updater: Updater

    var body: some View {
        switch updater.state {
        case .idle:
            EmptyView()
        case .checking:
            Section {
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text("Checking for updates…")
                }
            }
        case .upToDate:
            Section {
                HStack {
                    Label("You're on the latest version (\(Updater.currentVersion ?? "?")).", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Spacer()
                    Button("OK") { updater.dismiss() }
                }
            }
        case let .available(update):
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Version \(update.version) is available", systemImage: "arrow.down.circle.fill")
                        .font(.headline)
                    Text("You have version \(Updater.currentVersion ?? "?").")
                        .foregroundStyle(.secondary)
                    if !update.notes.isEmpty {
                        Text(update.notes)
                            .font(.callout)
                            .lineLimit(4)
                    }
                    HStack {
                        Button("Release Notes") { updater.openReleasePage(update) }
                            .buttonStyle(.link)
                        Spacer()
                        Button("Later") { updater.dismiss() }
                        Button("Install Update") { Task { await updater.install(update) } }
                            .buttonStyle(.borderedProminent)
                    }
                }
            }
        case let .installing(update):
            Section {
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text("Installing version \(update.version). The app reopens when it's done.")
                }
            }
        case let .failed(message, update):
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Label(message, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    HStack {
                        Spacer()
                        Button("Close") { updater.dismiss() }
                        if let update {
                            Button("Open Release Page") { updater.openReleasePage(update) }
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    Form {
        UpdateBanner(updater: Updater())
    }
    .formStyle(.grouped)
}
