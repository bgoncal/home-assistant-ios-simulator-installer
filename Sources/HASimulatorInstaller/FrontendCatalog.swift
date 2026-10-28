import Foundation

enum FrontendCatalog {
    static func resolve(_ channel: FrontendChannel, pullRequest: Int?, token: String?) async throws -> ResolvedFrontend {
        let gitHub = GitHubClient(token: token, repository: .frontend)
        switch channel {
        case .release:
            let asset = try await gitHub.latestReleaseAsset(withSuffix: "-py3-none-any.whl")
            return .release(tag: asset.tag, wheel: asset.url, size: asset.size)
        case .dev:
            return try await .artifact(gitHub.resolve(.latest))
        case .pullRequest:
            guard let pullRequest else { throw InstallerError("Enter a frontend pull request number or link.") }
            return try await .artifact(gitHub.resolve(.pullRequest(pullRequest)))
        }
    }
}
