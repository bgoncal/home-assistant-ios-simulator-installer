import SwiftUI

struct BuildSection: View {
    @Bindable var model: InstallerModel

    var body: some View {
        Section("What to test") {
            Picker("Build", selection: $model.usePullRequest) {
                Text("Latest version").tag(false)
                Text("A pull request").tag(true)
            }
            .pickerStyle(.segmented)

            if model.usePullRequest {
                TextField("Pull request", text: $model.pullRequestText, prompt: Text("Number or link, e.g. 6142"))
            }

            Picker("iOS version", selection: Binding(
                get: { model.selectedRuntimeID },
                set: { model.selectRuntime($0) }
            )) {
                ForEach(model.runtimes) { runtime in
                    Text(model.runtimeLabel(runtime)).tag(Optional(runtime.identifier))
                }
            }

            Picker("Device", selection: $model.deviceChoice) {
                ForEach(model.deviceChoices, id: \.self) { choice in
                    Text(choice.label).tag(Optional(choice))
                }
            }

            Toggle("Start fresh (removes the app and its data first)", isOn: $model.startFresh)
        }
        .disabled(model.phase.isWorking)
    }
}

#Preview {
    Form {
        BuildSection(model: InstallerModel())
    }
    .formStyle(.grouped)
}
