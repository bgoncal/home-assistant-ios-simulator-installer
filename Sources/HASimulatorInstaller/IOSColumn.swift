import SwiftUI

struct IOSColumn: View {
    @Bindable var model: InstallerModel
    let onInspect: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ColumnHeader(
                component: .iOSApp,
                detail: "The Home Assistant app in the iOS Simulator",
                status: model.status(of: .iOSApp),
                isOn: $model.iOSEnabled,
                isBusy: model.isBusy,
                onInspect: onInspect
            )

            Group {
                if model.iOSEnabled {
                    if model.isReady {
                        ColumnField(title: "Build") {
                            Picker("Build", selection: $model.usePullRequest) {
                                Text("Latest").tag(false)
                                Text("Pull request").tag(true)
                            }
                            .pickerStyle(.segmented)
                        }

                        if model.usePullRequest {
                            TextField("Pull request", text: $model.pullRequestText, prompt: Text("Number or link, e.g. 6142"))
                        }

                        ColumnField(title: "iOS version") {
                            Picker("iOS version", selection: Binding(
                                get: { model.selectedRuntimeID },
                                set: { model.selectRuntime($0) }
                            )) {
                                ForEach(model.runtimes) { runtime in
                                    Text(model.runtimeLabel(runtime)).tag(Optional(runtime.identifier))
                                }
                            }
                        }

                        ColumnField(title: "Device") {
                            Picker("Device", selection: $model.deviceChoice) {
                                ForEach(model.deviceChoices, id: \.self) { choice in
                                    Text(choice.label).tag(Optional(choice))
                                }
                            }
                        }

                        StartFreshToggle(detail: "Removes the app and its data first", isOn: $model.startFresh)
                    } else {
                        Text("Finish Setup in the sidebar to install the app.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .disabled(model.isBusy)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

#Preview {
    IOSColumn(model: InstallerModel(), onInspect: {})
        .padding()
        .frame(width: 320)
}
