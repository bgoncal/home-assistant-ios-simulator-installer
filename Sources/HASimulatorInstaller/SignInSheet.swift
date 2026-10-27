import SwiftUI

struct SignInSheet: View {
    let model: InstallerModel
    let code: DeviceCode

    var body: some View {
        VStack(spacing: 16) {
            Text("Sign in with GitHub")
                .font(.title2.bold())
            Text("Copy this code, then paste it on the GitHub page that opens and approve the request.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Text("The code is approved for whichever account your browser is signed in to on github.com. To use another account, switch accounts there first.")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Text(code.userCode)
                .font(.system(size: 32, weight: .semibold, design: .monospaced))
                .textSelection(.enabled)
            Button("Copy Code & Open GitHub") { model.copyCodeAndOpenGitHub(code) }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            HStack(spacing: 8) {
                ProgressView().controlSize(.small)
                Text("Waiting for you to approve…")
                    .foregroundStyle(.secondary)
            }
            Button("Cancel", role: .cancel) { model.cancelSignIn() }
                .keyboardShortcut(.cancelAction)
        }
        .padding(24)
        .frame(width: 380)
    }
}

#Preview {
    SignInSheet(
        model: InstallerModel(),
        code: DeviceCode(
            deviceCode: "preview",
            userCode: "WDJB-MJHT",
            verificationURI: URL(string: "https://github.com/login/device")!,
            expiresIn: 900,
            interval: 5
        )
    )
}
