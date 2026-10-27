import SwiftUI

struct XcodeVersionsSheet: View {
    @Bindable var model: InstallerModel

    var body: some View {
        VersionsSheetContainer(
            title: "Xcode versions",
            footer: "Xcode downloads come from Apple's developer site, which asks you to sign in with a free Apple Account. The app watches your Downloads folder and installs Xcode into Applications when the download finishes.",
            isLoading: model.xcodeReleases.isEmpty && model.catalogError == nil,
            model: model
        ) {
            ForEach(model.visibleXcodeReleases) { release in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(release.displayName)
                        Text(subtitle(for: release))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if model.isInstalled(release) {
                        Text("Installed").foregroundStyle(.secondary)
                    } else {
                        Button("Download") { model.download(release) }
                            .disabled(!release.runsOnThisMac || model.activity != nil)
                    }
                }
            }
        } extraActions: {
            Button("Open Apple's Download Page") { model.openAppleDownloads() }
        }
    }

    private func subtitle(for release: XcodeRelease) -> String {
        var parts = [release.build]
        if let date = release.releaseDate {
            parts.append(date.formatted(date: .abbreviated, time: .omitted))
        }
        if !release.runsOnThisMac, let required = release.requiredMacOS {
            parts.append("Needs macOS \(required)")
        }
        return parts.joined(separator: " · ")
    }
}

#Preview {
    XcodeVersionsSheet(model: InstallerModel())
}
