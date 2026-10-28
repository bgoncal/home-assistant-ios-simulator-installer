import SwiftUI

struct FrontendInspector: View {
    let model: InstallerModel

    var body: some View {
        Form {
            InspectorStatusSection(status: model.status(of: .frontend))

            Section("Frontend") {
                LabeledContent("Build", value: model.server.running?.frontendTitle ?? "The one included with Core")
                if let directory = model.server.running?.frontendDirectory {
                    LabeledContent("Served from") {
                        Text(directory.path)
                            .textSelection(.enabled)
                            .lineLimit(2)
                            .truncationMode(.middle)
                    }
                }
                Button("Show Downloaded Builds") { model.server.revealFrontendBuilds() }
            }

            Section {
                ActivityLogView(entries: model.activityLog.entries(for: .frontend))
            } header: {
                Text("Log")
            } footer: {
                Text("Errors in the web interface show up in the browser's developer tools and in the Core server log.")
            }
        }
        .formStyle(.grouped)
    }
}

#Preview {
    FrontendInspector(model: InstallerModel())
        .frame(width: 360, height: 700)
}
