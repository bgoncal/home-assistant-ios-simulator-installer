import SwiftUI

struct FrontendColumn: View {
    let model: InstallerModel
    let onInspect: () -> Void

    var body: some View {
        @Bindable var server = model.server
        VStack(alignment: .leading, spacing: 12) {
            ColumnHeader(
                component: .frontend,
                detail: "The web interface, served by Core",
                status: model.status(of: .frontend),
                isOn: $server.frontendEnabled,
                isBusy: model.isBusy,
                onInspect: onInspect
            )

            Group {
                if server.frontendEnabled {
                    ColumnField(title: "Version") {
                        Picker("Version", selection: $server.frontendChannel) {
                            ForEach(FrontendChannel.allCases) { channel in
                                Text(channel.label).tag(channel)
                            }
                        }
                    }

                    if server.frontendChannel == .pullRequest {
                        ColumnField(title: "Pull request") {
                            TextField("Pull request", text: $server.frontendPullRequestText, prompt: Text("Number or link, e.g. 25000"))
                        }
                    }

                    if server.frontendChannel.needsGitHub, !model.isSignedIn {
                        Text("Sign in to GitHub in Setup to download this build.")
                            .font(.callout)
                            .foregroundStyle(.orange)
                    } else {
                        Text("Replaces the frontend that comes with Core.")
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
    FrontendColumn(model: InstallerModel(), onInspect: {})
        .padding()
        .frame(width: 320)
}
