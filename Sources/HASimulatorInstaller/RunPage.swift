import SwiftUI

struct RunPage: View {
    let model: InstallerModel
    let updater: Updater
    let onInspect: (Component) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if updater.state != .idle {
                    GroupBox {
                        UpdateBanner(updater: updater)
                            .padding(6)
                    }
                }

                Text("What to run")
                    .font(.headline)
                GroupBox {
                    HStack(alignment: .top, spacing: 16) {
                        IOSColumn(model: model) { onInspect(.iOSApp) }
                        Divider()
                        AndroidColumn(model: model) { onInspect(.androidApp) }
                        Divider()
                        CoreColumn(model: model) { onInspect(.core) }
                        Divider()
                        FrontendColumn(model: model) { onInspect(.frontend) }
                    }
                    .padding(10)
                }

                GroupBox {
                    RunSection(model: model)
                        .padding(10)
                }

                if let errorMessage = model.errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .textSelection(.enabled)
                }
            }
            .padding(20)
        }
        .navigationTitle("Run")
    }
}

#Preview {
    RunPage(model: InstallerModel(), updater: Updater(), onInspect: { _ in })
        .frame(width: 1100, height: 700)
}
