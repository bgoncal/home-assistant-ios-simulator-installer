import SwiftUI

struct OnboardingSetupStep: View {
    let model: InstallerModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Get your Mac ready")
                .font(.title2.bold())
            Text("Only what your choices need. Each step runs right here.")
                .foregroundStyle(.secondary)

            Form {
                if model.iOSEnabled {
                    SetupRow(
                        title: "Xcode",
                        detail: model.selectedXcode.map { "\($0.displayName) found" } ?? "Free from the App Store. It provides the iOS Simulator.",
                        isDone: model.hasXcode
                    ) {
                        if !model.hasXcode {
                            Button("Get Xcode") { model.getXcodeFromAppStore() }
                        }
                    }
                    if let licenseMessage = model.licenseMessage {
                        SetupRow(title: "Xcode license", detail: licenseMessage, isDone: false) {
                            Button("Open Xcode") { model.openSelectedXcode() }
                        }
                    }
                    if model.hasXcode, model.licenseMessage == nil {
                        SetupRow(
                            title: "iOS Simulator",
                            detail: model.hasSimulators
                                ? model.runtimes.map(model.runtimeLabel).joined(separator: ", ")
                                : "A one-time download of several gigabytes.",
                            isDone: model.hasSimulators
                        ) {
                            if !model.hasSimulators {
                                Button("Download…") { model.showsRuntimeVersions = true }
                                    .disabled(model.activity != nil)
                            }
                        }
                    }
                    if let activity = model.activity {
                        ActivityRow(activity: activity) { model.cancelActivity() }
                    }
                }

                if model.android.enabled {
                    AndroidSetupRow(android: model.android)
                }

                if model.onboardingNeedsGitHub {
                    SetupRow(
                        title: "GitHub account",
                        detail: model.username.map { "Signed in as \($0)" } ?? "Needed to download test builds.",
                        isDone: model.isSignedIn
                    ) {
                        GitHubAccountMenu(model: model)
                    }
                }

                if model.server.isActive {
                    SetupRow(title: "Core", detail: "Nothing to set up. The first run downloads it.", isDone: true) {
                        EmptyView()
                    }
                }
            }
            .formStyle(.grouped)
            .scrollDisabled(false)
        }
    }
}

#Preview {
    OnboardingSetupStep(model: InstallerModel())
        .padding(32)
        .frame(width: 680, height: 420)
}
