import SwiftUI

struct VersionsSheetContainer<Rows: View, ExtraActions: View>: View {
    let title: String
    let footer: String
    let isLoading: Bool
    @Bindable var model: InstallerModel
    @ViewBuilder let rows: () -> Rows
    @ViewBuilder let extraActions: () -> ExtraActions
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title).font(.title2.bold())
                Spacer()
                Toggle("Show betas", isOn: $model.showsBetas)
            }

            Group {
                if let catalogError = model.catalogError {
                    ContentUnavailableView {
                        Label("Couldn't load versions", systemImage: "wifi.exclamationmark")
                    } description: {
                        Text(catalogError)
                    } actions: {
                        Button("Try Again") { Task { await model.loadCatalogs() } }
                    }
                } else if isLoading {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List { rows() }
                }
            }
            .frame(height: 360)

            Text(footer)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                extraActions()
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 520)
        .task {
            if model.xcodeReleases.isEmpty || model.runtimeReleases.isEmpty {
                await model.loadCatalogs()
            }
        }
    }
}

#Preview {
    VersionsSheetContainer(title: "Versions", footer: "Footer", isLoading: true, model: InstallerModel()) {
        EmptyView()
    } extraActions: {
        EmptyView()
    }
}
