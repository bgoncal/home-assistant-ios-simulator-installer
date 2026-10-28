import AppKit
import SwiftUI

struct DownloadsPage: View {
    let model: InstallerModel
    @State private var items: [StorageGroup: [StoredItem]] = [:]
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section {
                HStack {
                    Text("Total")
                    Spacer()
                    if isLoading {
                        ProgressView().controlSize(.small)
                    } else {
                        Text(total.formatted(.byteCount(style: .file)))
                            .monospacedDigit()
                    }
                }
            } footer: {
                Text("Everything here can be downloaded again. Your server's data isn't listed and isn't affected.")
            }

            ForEach(StorageGroup.allCases) { group in
                Section {
                    let groupItems = items[group] ?? []
                    if groupItems.isEmpty {
                        Text(isLoading ? "Checking…" : "Nothing downloaded")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(groupItems) { item in
                        StoredItemRow(item: item, isInUse: isInUse(item, in: group)) {
                            Task { await delete(item) }
                        }
                    }
                } header: {
                    HStack {
                        Text(group.title)
                        Spacer()
                        Button("Show in Finder") { showInFinder(group) }
                            .buttonStyle(.link)
                            .font(.caption)
                    }
                } footer: {
                    Text(group.detail)
                }
            }

            if let errorMessage {
                Section {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Downloads")
        .task { await reload() }
    }

    private var total: Int64 {
        items.values.joined().reduce(0) { $0 + $1.size }
    }

    private func isInUse(_ item: StoredItem, in group: StorageGroup) -> Bool {
        guard let running = model.server.running else { return group == .tools && model.server.isRunning }
        switch group {
        case .iOSBuilds:
            return false
        case .coreInstalls:
            return item.url.lastPathComponent == running.coreKey
        case .frontendBuilds:
            return running.frontendDirectory?.standardizedFileURL == item.url.standardizedFileURL
        case .tools:
            return true
        }
    }

    private func reload() async {
        isLoading = true
        var loaded: [StorageGroup: [StoredItem]] = [:]
        for group in StorageGroup.allCases {
            loaded[group] = await StorageCatalog.items(in: group)
        }
        items = loaded
        isLoading = false
    }

    private func delete(_ item: StoredItem) async {
        errorMessage = nil
        do {
            try await StorageCatalog.delete(item)
        } catch {
            errorMessage = error.localizedDescription
        }
        await reload()
    }

    private func showInFinder(_ group: StorageGroup) {
        try? FileManager.default.createDirectory(at: group.directory, withIntermediateDirectories: true)
        NSWorkspace.shared.activateFileViewerSelecting([group.directory])
    }
}

#Preview {
    DownloadsPage(model: InstallerModel())
        .frame(width: 700, height: 700)
}
