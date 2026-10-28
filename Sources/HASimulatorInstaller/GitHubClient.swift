import Foundation

struct GitHubClient: Sendable {
    let token: String?
    var repository: GitHubRepository = .iOS

    private var repositoryPath: String { repository.path }

    func username() async throws -> String {
        try await get("user", as: User.self).login
    }

    func resolve(_ source: BuildSource) async throws -> ResolvedBuild {
        switch source {
        case .latest:
            return try await resolveLatest()
        case let .pullRequest(number):
            return try await resolvePullRequest(number)
        }
    }

    func branchHead() async throws -> String {
        try await get("\(repositoryPath)/commits/\(repository.branch)", as: Commit.self).sha
    }

    func pullRequestHead(_ number: Int) async throws -> (sha: String, title: String) {
        let pullRequest = try await pullRequest(number)
        return (pullRequest.head.sha, pullRequest.title)
    }

    func latestReleaseAsset(withSuffix suffix: String) async throws -> (tag: String, url: URL, size: Int) {
        let release = try await get("\(repositoryPath)/releases/latest", as: Release.self)
        guard let asset = release.assets.first(where: { $0.name.hasSuffix(suffix) }) else {
            throw InstallerError("The latest release of \(repository.displayName) has no \(suffix) file.")
        }
        return (release.tagName, asset.browserDownloadUrl, asset.size)
    }

    func downloadRequest(artifactID: Int) -> URLRequest {
        request(for: "\(repositoryPath)/actions/artifacts/\(artifactID)/zip")
    }

    private func resolveLatest() async throws -> ResolvedBuild {
        let runs = try await get(
            "\(repositoryPath)/actions/workflows/\(repository.workflowFile)/runs",
            query: ["branch": repository.branch, "event": "push", "status": "success", "per_page": "10"],
            as: WorkflowRuns.self
        ).workflowRuns

        for run in runs {
            if let artifact = try await simulatorArtifact(for: run, named: repository.artifactName) {
                return ResolvedBuild(
                    artifactID: artifact.id,
                    artifactSize: artifact.sizeInBytes,
                    title: "Latest on \(repository.branch): \(run.displayTitle)",
                    commit: String(run.headSha.prefix(7)),
                    builtAt: artifact.createdAt
                )
            }
        }
        throw InstallerError("No recent build of the \(repository.displayName) on \(repository.branch) has a \(repository.buildName). Try again later.")
    }

    private func resolvePullRequest(_ number: Int) async throws -> ResolvedBuild {
        let pullRequest = try await pullRequest(number)

        let runs = try await get(
            "\(repositoryPath)/actions/workflows/\(repository.pullRequestWorkflowFile ?? repository.workflowFile)/runs",
            query: ["head_sha": pullRequest.head.sha, "per_page": "20"],
            as: WorkflowRuns.self
        ).workflowRuns

        for run in runs {
            if let artifact = try await simulatorArtifact(
                for: run,
                named: repository.pullRequestArtifactName ?? repository.artifactName
            ) {
                return ResolvedBuild(
                    artifactID: artifact.id,
                    artifactSize: artifact.sizeInBytes,
                    title: "#\(number): \(pullRequest.title)",
                    commit: String(pullRequest.head.sha.prefix(7)),
                    builtAt: artifact.createdAt
                )
            }
        }

        if runs.isEmpty {
            throw InstallerError(
                "The checks haven't started for \(repository.displayName) pull request #\(number) yet. If it comes from a new contributor, a maintainer may need to approve them first."
            )
        }
        if runs.contains(where: { $0.status != "completed" }) {
            throw InstallerError(
                "The checks for \(repository.displayName) pull request #\(number) are still running. Try again in a few minutes."
            )
        }
        throw InstallerError(
            "The checks for \(repository.displayName) pull request #\(number) failed, or its \(repository.buildName) has expired. Ask the pull request author."
        )
    }

    private func pullRequest(_ number: Int) async throws -> PullRequest {
        do {
            return try await get("\(repositoryPath)/pulls/\(number)", as: PullRequest.self)
        } catch let error as HTTPError where error.status == 404 {
            throw InstallerError("\(repository.displayName) pull request #\(number) doesn't exist.")
        }
    }

    private func simulatorArtifact(for run: WorkflowRun, named name: String) async throws -> Artifact? {
        try await get("\(repositoryPath)/actions/runs/\(run.id)/artifacts", as: Artifacts.self)
            .artifacts
            .first { $0.name == name && !$0.expired }
    }

    private func get<T: Decodable>(_ path: String, query: [String: String] = [:], as type: T.Type) async throws -> T {
        let (data, response) = try await URLSession.shared.data(for: request(for: path, query: query))
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200 ..< 300).contains(status) else {
            if status == 401 {
                throw InstallerError("Your GitHub sign-in has expired. Sign out and sign in again.")
            }
            if status == 403 || status == 429, token == nil {
                throw InstallerError("GitHub is limiting requests from this Mac. Sign in to GitHub in Setup and try again.")
            }
            throw HTTPError(status: status)
        }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: data)
    }

    private func request(for path: String, query: [String: String] = [:]) -> URLRequest {
        var components = URLComponents(string: "https://api.github.com/\(path)")!
        if !query.isEmpty {
            components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        var request = URLRequest(url: components.url!)
        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        request.setValue("HASimulatorInstaller", forHTTPHeaderField: "User-Agent")
        return request
    }

    private struct HTTPError: LocalizedError {
        let status: Int
        var errorDescription: String? { "GitHub returned an unexpected response (\(status))." }
    }

    private struct User: Decodable {
        let login: String
    }

    private struct PullRequest: Decodable {
        struct Head: Decodable {
            let sha: String
        }

        let title: String
        let head: Head
    }

    private struct Commit: Decodable {
        let sha: String
    }

    private struct Release: Decodable {
        struct Asset: Decodable {
            let name: String
            let size: Int
            let browserDownloadUrl: URL
        }

        let tagName: String
        let assets: [Asset]
    }

    private struct WorkflowRuns: Decodable {
        let workflowRuns: [WorkflowRun]
    }

    private struct WorkflowRun: Decodable {
        let id: Int
        let headSha: String
        let displayTitle: String
        let status: String?
    }

    private struct Artifacts: Decodable {
        let artifacts: [Artifact]
    }

    private struct Artifact: Decodable {
        let id: Int
        let name: String
        let sizeInBytes: Int
        let expired: Bool
        let createdAt: Date
    }
}
