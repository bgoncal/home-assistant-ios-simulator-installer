import SwiftUI

struct RunPage: View {
    let model: InstallerModel
    let updater: Updater
    let onInspect: (Component) -> Void

    var body: some View {
        Form {
            UpdateBanner(updater: updater)
            Section("What to run") {
                HStack(alignment: .top, spacing: 20) {
                    IOSColumn(model: model) { onInspect(.iOSApp) }
                    Divider()
                    CoreColumn(model: model) { onInspect(.core) }
                    Divider()
                    FrontendColumn(model: model) { onInspect(.frontend) }
                }
                .padding(.vertical, 4)
            }
            RunSection(model: model)
            if let errorMessage = model.errorMessage {
                Section {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .textSelection(.enabled)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Run")
    }
}

#Preview {
    RunPage(model: InstallerModel(), updater: Updater(), onInspect: { _ in })
        .frame(width: 900, height: 700)
}
