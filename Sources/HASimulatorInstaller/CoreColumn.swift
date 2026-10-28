import SwiftUI

struct CoreColumn: View {
    let model: InstallerModel
    let onInspect: () -> Void

    var body: some View {
        @Bindable var server = model.server
        VStack(alignment: .leading, spacing: 12) {
            ColumnHeader(
                component: .core,
                detail: "The Home Assistant server, running on this Mac",
                status: model.status(of: .core),
                isOn: $server.coreEnabled,
                isBusy: model.isBusy,
                onInspect: onInspect
            )

            Group {
                if server.coreEnabled {
                    ColumnField(title: "Version") {
                        Picker("Version", selection: $server.coreChannel) {
                            ForEach(CoreChannel.allCases) { channel in
                                Text(channel.label).tag(channel)
                            }
                        }
                    }

                    if server.coreChannel == .pullRequest {
                        ColumnField(title: "Pull request") {
                            TextField("Pull request", text: $server.corePullRequestText, prompt: Text("Number or link, e.g. 150000"))
                        }
                    }
                } else if server.usesDefaultCore {
                    Text("The frontend needs a server, so the latest release of Core runs with it.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if server.isActive {
                    StartFreshToggle(detail: "Erases the server's data first", isOn: $server.startFresh)
                }
            }
            .disabled(model.isBusy)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

#Preview {
    CoreColumn(model: InstallerModel(), onInspect: {})
        .padding()
        .frame(width: 320)
}
