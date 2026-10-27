import Foundation

enum GitHubAuth {
    static let newTokenURL = URL(string: "https://github.com/settings/personal-access-tokens/new")!
    private static let tokenAccount = "github-token"
    private static let sourceKey = "githubCredentialSource"

    static var storedToken: String? {
        KeychainStore.read(account: tokenAccount)
    }

    static var savedSource: CredentialSource? {
        get { UserDefaults.standard.string(forKey: sourceKey).flatMap(CredentialSource.init(rawValue:)) }
        set { UserDefaults.standard.set(newValue?.rawValue, forKey: sourceKey) }
    }

    static func store(token: String) {
        KeychainStore.write(token, account: tokenAccount)
    }

    static func deleteStoredToken() {
        KeychainStore.delete(account: tokenAccount)
    }

    static func gitHubCLIAccounts() async -> [String] {
        guard let gh = gitHubCLIPath,
              let result = try? await ProcessRunner.run(gh, ["auth", "status", "--hostname", "github.com", "--json", "hosts"]),
              let status = try? JSONDecoder().decode(CLIStatus.self, from: Data(result.output.utf8)) else { return [] }
        return (status.hosts["github.com"] ?? [])
            .filter { $0.state == "success" }
            .sorted { ($0.active ?? false) && !($1.active ?? false) }
            .map(\.login)
    }

    static func gitHubCLIToken(for login: String? = nil) async -> String? {
        guard let gh = gitHubCLIPath else { return nil }
        var arguments = ["auth", "token", "--hostname", "github.com"]
        if let login {
            arguments += ["--user", login]
        }
        guard let result = try? await ProcessRunner.run(gh, arguments), result.succeeded else { return nil }
        let token = result.output.trimmingCharacters(in: .whitespacesAndNewlines)
        return token.isEmpty ? nil : token
    }

    static func requestDeviceCode(clientID: String) async throws -> DeviceCode {
        let data = try await post(
            "https://github.com/login/device/code",
            form: ["client_id": clientID, "scope": ""]
        )
        return try JSONDecoder().decode(DeviceCode.self, from: data)
    }

    static func waitForToken(clientID: String, deviceCode: DeviceCode) async throws -> String {
        var interval = max(deviceCode.interval, 5)
        let deadline = Date().addingTimeInterval(TimeInterval(deviceCode.expiresIn))

        while Date() < deadline {
            try await Task.sleep(for: .seconds(interval))
            let data = try await post(
                "https://github.com/login/oauth/access_token",
                form: [
                    "client_id": clientID,
                    "device_code": deviceCode.deviceCode,
                    "grant_type": "urn:ietf:params:oauth:grant-type:device_code",
                ]
            )
            let response = try JSONDecoder().decode(TokenResponse.self, from: data)
            if let token = response.accessToken {
                return token
            }
            switch response.error {
            case "authorization_pending":
                continue
            case "slow_down":
                interval += 5
            case "access_denied":
                throw InstallerError("Sign-in was cancelled on GitHub.")
            case "expired_token":
                throw InstallerError("The sign-in code expired. Try again.")
            default:
                throw InstallerError(response.errorDescription ?? "GitHub sign-in failed.")
            }
        }
        throw InstallerError("The sign-in code expired. Try again.")
    }

    private static var gitHubCLIPath: String? {
        ["/opt/homebrew/bin/gh", "/usr/local/bin/gh"].first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    private static func post(_ url: String, form: [String: String]) async throws -> Data {
        var components = URLComponents()
        components.queryItems = form.map { URLQueryItem(name: $0.key, value: $0.value) }
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = Data((components.percentEncodedQuery ?? "").utf8)
        let (data, _) = try await URLSession.shared.data(for: request)
        return data
    }

    private struct CLIStatus: Decodable {
        struct Account: Decodable {
            let login: String
            let state: String?
            let active: Bool?
        }

        let hosts: [String: [Account]]
    }

    private struct TokenResponse: Decodable {
        let accessToken: String?
        let error: String?
        let errorDescription: String?

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case error
            case errorDescription = "error_description"
        }
    }
}
