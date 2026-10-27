import SwiftUI

struct TokenEntrySheet: View {
    let model: InstallerModel
    @State private var token = ""
    @State private var isChecking = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Use a GitHub access token")
                .font(.title2.bold())
            Text("Create a token on GitHub with the default settings (public repositories, read-only access is enough), then paste it here. It's saved in your Mac's keychain.")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Button("Create a Token on GitHub") { model.openNewTokenPage() }
                .buttonStyle(.link)
            SecureField("Token", text: $token, prompt: Text("github_pat_…"))
                .onSubmit(save)
            if let error = model.tokenEntryError {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
            }
            HStack {
                Spacer()
                if isChecking {
                    ProgressView().controlSize(.small)
                }
                Button("Cancel", role: .cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Use Token", action: save)
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    .disabled(token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isChecking)
            }
        }
        .padding(20)
        .frame(width: 440)
    }

    private func save() {
        isChecking = true
        Task {
            await model.useAccessToken(token)
            isChecking = false
        }
    }
}

#Preview {
    TokenEntrySheet(model: InstallerModel())
}
