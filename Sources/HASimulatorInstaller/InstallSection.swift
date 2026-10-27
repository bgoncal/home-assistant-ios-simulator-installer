import SwiftUI

struct InstallSection: View {
    let model: InstallerModel

    var body: some View {
        Section {
            switch model.phase {
            case .idle:
                EmptyView()
            case let .working(message, progress):
                VStack(alignment: .leading) {
                    Text(message)
                    if let progress {
                        ProgressView(value: progress)
                    } else {
                        ProgressView().progressViewStyle(.linear)
                    }
                }
            case let .done(summary):
                Label(summary, systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }

            HStack {
                if model.installedDevice != nil {
                    Button("Take Screenshot") { Task { await model.takeScreenshot() } }
                    Button(model.isRecording ? "Stop Recording" : "Record Screen") { model.toggleRecording() }
                }
                Spacer()
                Button("Stop") { Task { await model.stop() } }
                    .keyboardShortcut(".", modifiers: .command)
                    .disabled(!model.canStop)
                Button("Install & Open") { model.install() }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    .disabled(!model.canInstall)
            }
        }
    }
}

#Preview {
    Form {
        InstallSection(model: InstallerModel())
    }
    .formStyle(.grouped)
}
