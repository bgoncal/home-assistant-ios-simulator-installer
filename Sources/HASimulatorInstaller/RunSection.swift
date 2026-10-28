import SwiftUI

struct RunSection: View {
    let model: InstallerModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if case let .working(message, progress) = model.server.phase {
                PhaseRow(title: "Server", message: message, progress: progress)
            }
            if case let .working(message, progress) = model.phase {
                PhaseRow(title: "iOS app", message: message, progress: progress)
            }
            if case let .working(message, progress) = model.android.phase {
                PhaseRow(title: "Android app", message: message, progress: progress)
            }

            if let running = model.server.running {
                ServerStatusView(model: model, running: running)
            }
            if let serverError = model.server.errorMessage {
                HStack(alignment: .firstTextBaseline) {
                    Label(serverError, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .textSelection(.enabled)
                    Spacer()
                    Button("Show Log") { model.server.showLog() }
                }
            }

            if case let .done(summary) = model.phase, model.iOSEnabled {
                Label(summary, systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
            if let appError = model.appErrorMessage {
                Label(appError, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .textSelection(.enabled)
            }
            if case let .done(summary) = model.android.phase, model.android.enabled {
                Label(summary, systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
            if let androidError = model.android.errorMessage {
                Label(androidError, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .textSelection(.enabled)
            }

            HStack {
                if model.installedDevice != nil {
                    Button("Take Screenshot") { Task { await model.takeScreenshot() } }
                    Button(model.isRecording ? "Stop Recording" : "Record Screen") { model.toggleRecording() }
                }
                if model.android.isRunning {
                    Button("Android Screenshot") { Task { await model.takeAndroidScreenshot() } }
                }
                Spacer()
                Button("Stop") { Task { await model.stop() } }
                    .disabled(!model.canStop)
                Button("Run") { model.run() }
                    .buttonStyle(.borderedProminent)
                    .disabled(!model.canRun)
            }
        }
    }
}

#Preview {
    RunSection(model: InstallerModel())
        .padding()
        .frame(width: 900)
}
