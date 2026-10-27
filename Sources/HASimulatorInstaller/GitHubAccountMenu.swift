import SwiftUI

struct GitHubAccountMenu: View {
    let model: InstallerModel

    var body: some View {
        Menu(model.isSignedIn ? "Change Account" : "Sign In") {
            if !model.gitHubCLIAccounts.isEmpty {
                Section("GitHub CLI accounts") {
                    ForEach(model.gitHubCLIAccounts, id: \.self) { login in
                        Toggle(login, isOn: Binding(
                            get: { model.credentialSource == .gitHubCLI(login) },
                            set: { _ in Task { await model.useGitHubCLIAccount(login) } }
                        ))
                    }
                }
            }

            Section {
                if model.canSignInWithGitHub {
                    Button("Sign In with GitHub…") { model.signIn() }
                }
                Button("Use an Access Token…") {
                    model.tokenEntryError = nil
                    model.showsTokenEntry = true
                }
            }

            if model.isSignedIn {
                Section {
                    Button("Sign Out") { model.signOut() }
                }
            }
        }
        .fixedSize()
    }
}

#Preview {
    Form {
        GitHubAccountMenu(model: InstallerModel())
    }
    .formStyle(.grouped)
}
