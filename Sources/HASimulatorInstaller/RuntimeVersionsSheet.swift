import SwiftUI

struct RuntimeVersionsSheet: View {
    @Bindable var model: InstallerModel

    var body: some View {
        VersionsSheetContainer(
            title: "iOS Simulator versions",
            footer: "Downloaded from Apple with \(model.selectedXcode?.displayName ?? "the selected Xcode"). An Xcode can only run the iOS versions it supports, so a newer iOS may need a newer Xcode.",
            isLoading: model.runtimeReleases.isEmpty && model.catalogError == nil,
            model: model
        ) {
            ForEach(model.visibleRuntimeReleases) { release in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(release.displayName)
                        Text("\(release.build) · \(release.fileSize.formatted(.byteCount(style: .file)))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if release.isInstalled(in: model.runtimes) {
                        Text("Installed").foregroundStyle(.secondary)
                    } else {
                        Button("Download") { model.download(release) }
                            .disabled(model.activity != nil)
                    }
                }
            }
        } extraActions: {
            EmptyView()
        }
    }
}

#Preview {
    RuntimeVersionsSheet(model: InstallerModel())
}
