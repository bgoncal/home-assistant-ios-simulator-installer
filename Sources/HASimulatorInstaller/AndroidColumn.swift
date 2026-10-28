import SwiftUI

struct AndroidColumn: View {
    let model: InstallerModel
    let onInspect: () -> Void

    var body: some View {
        @Bindable var android = model.android
        VStack(alignment: .leading, spacing: 12) {
            ColumnHeader(
                component: .androidApp,
                detail: "The Home Assistant app in the Android emulator",
                status: model.status(of: .androidApp),
                isOn: $android.enabled,
                isBusy: model.isBusy,
                onInspect: onInspect
            )

            if android.enabled {
                Group {
                    ColumnField(title: "Build") {
                        Picker("Build", selection: $android.usePullRequest) {
                            Text("Latest").tag(false)
                            Text("Pull request").tag(true)
                        }
                        .pickerStyle(.segmented)
                    }

                    if android.usePullRequest {
                        TextField("Pull request", text: $android.pullRequestText, prompt: Text("Number or link, e.g. 5800"))
                    }

                    ColumnField(title: "Version") {
                        Picker("Version", selection: $android.flavor) {
                            ForEach(AndroidFlavor.allCases) { flavor in
                                Text(flavor.label).tag(flavor)
                            }
                        }
                    }
                    Text(android.flavor.detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    if android.isReady {
                        ColumnField(title: "Device") {
                            HStack {
                                Picker("Device", selection: $android.device) {
                                    ForEach(android.devices) { device in
                                        Text(device.displayName).tag(Optional(device))
                                    }
                                }
                                Button { android.showsAddDevice = true } label: {
                                    Image(systemName: "plus")
                                }
                                .help("Add an emulator")
                                .disabled(android.activity != nil)
                            }
                        }

                        if let activity = android.activity {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(activity.detail ?? activity.title)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if let progress = activity.progress {
                                    ProgressView(value: progress)
                                } else {
                                    ProgressView().progressViewStyle(.linear)
                                }
                            }
                        }

                        StartFreshToggle(detail: "Removes the app and its data first", isOn: $android.startFresh)
                    } else {
                        Text("Set up the Android emulator in Setup to install the app, or download the APK.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Button("Download APK") { model.downloadAPK() }
                        .disabled(!model.isSignedIn || android.selectedSource == nil)
                        .help(model.isSignedIn ? "Save the APK to your Downloads folder" : "Sign in to GitHub in Setup first")
                }
                .disabled(model.isBusy)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

#Preview {
    AndroidColumn(model: InstallerModel(), onInspect: {})
        .padding()
        .frame(width: 260)
}
