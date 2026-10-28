import Foundation

enum CoreCatalog {
    static func resolve(_ channel: CoreChannel, pullRequest: Int?, token: String?) async throws -> ResolvedCore {
        let gitHub = GitHubClient(token: token, repository: .core)
        switch channel {
        case .release:
            let project = try await fetchProject()
            return try await pyPIRelease(project.info.version, title: project.info.version)
        case .beta:
            let project = try await fetchProject()
            let newest = project.newestVersion ?? project.info.version
            let title = newest == project.info.version ? "\(newest) (no beta is out right now)" : newest
            return try await pyPIRelease(newest, title: title)
        case .dev:
            let sha = try await gitHub.branchHead()
            return ResolvedCore(
                title: "\(GitHubRepository.core.branch) (\(sha.prefix(7)))",
                cacheKey: "source-\(sha)",
                package: .source(archive: archiveURL("\(sha)"))
            )
        case .pullRequest:
            guard let pullRequest else { throw InstallerError("Enter a Core pull request number or link.") }
            let head = try await gitHub.pullRequestHead(pullRequest)
            return ResolvedCore(
                title: "#\(pullRequest): \(head.title) (\(head.sha.prefix(7)))",
                cacheKey: "source-\(head.sha)",
                package: .source(archive: archiveURL("refs/pull/\(pullRequest)/head"))
            )
        }
    }

    static func pythonRequirement(inSource directory: URL) throws -> String {
        let pyproject = try String(contentsOf: directory.appendingPathComponent("pyproject.toml"), encoding: .utf8)
        guard let match = pyproject.firstMatch(of: /requires-python\s*=\s*"([^"]+)"/) else {
            throw InstallerError("This version of Home Assistant Core doesn't say which Python it needs.")
        }
        return String(match.1)
    }

    static func pythonVersion(for requirement: String) -> String {
        guard let match = requirement.firstMatch(of: />=\s*(\d+)\.(\d+)/) else { return requirement }
        return "\(match.1).\(match.2)"
    }

    private static func pyPIRelease(_ version: String, title: String) async throws -> ResolvedCore {
        let url = URL(string: "https://pypi.org/pypi/homeassistant/\(version)/json")!
        let release = try await fetch(url, as: Project.self)
        return ResolvedCore(
            title: title,
            cacheKey: "release-\(version)",
            package: .pyPI(version: version, requiresPython: release.info.requiresPython ?? ">=3.13")
        )
    }

    private static func archiveURL(_ reference: String) -> URL {
        let repository = GitHubRepository.core
        return URL(string: "https://codeload.github.com/\(repository.owner)/\(repository.name)/tar.gz/\(reference)")!
    }

    private static func fetchProject() async throws -> Project {
        try await fetch(Constants.pyPIProjectURL, as: Project.self)
    }

    private static func fetch<T: Decodable>(_ url: URL, as type: T.Type) async throws -> T {
        let (data, response) = try await URLSession.shared.data(from: url)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw InstallerError("Couldn't get the list of Home Assistant Core versions. Check your internet connection and try again.")
        }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(T.self, from: data)
    }

    private struct Project: Decodable {
        struct Info: Decodable {
            let version: String
            let requiresPython: String?
        }

        struct File: Decodable {
            let uploadTimeIso8601: String?
            let yanked: Bool?
        }

        let info: Info
        let releases: [String: [File]]?

        var newestVersion: String? {
            releases?
                .compactMap { version, files -> (String, String)? in
                    let uploaded = files.filter { $0.yanked != true }.compactMap(\.uploadTimeIso8601).max()
                    return uploaded.map { (version, $0) }
                }
                .max { $0.1 < $1.1 }?
                .0
        }
    }
}
