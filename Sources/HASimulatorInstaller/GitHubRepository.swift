import Foundation

struct GitHubRepository: Sendable {
    let owner: String
    let name: String
    let displayName: String
    let workflowFile: String
    let branch: String
    let artifactName: String
    let buildName: String

    var path: String { "repos/\(owner)/\(name)" }

    static let iOS = GitHubRepository(
        owner: "home-assistant",
        name: "iOS",
        displayName: "iOS app",
        workflowFile: "ci.yml",
        branch: "main",
        artifactName: "ios-simulator",
        buildName: "simulator app"
    )

    static let frontend = GitHubRepository(
        owner: "home-assistant",
        name: "frontend",
        displayName: "Frontend",
        workflowFile: "ci.yaml",
        branch: "dev",
        artifactName: "frontend-build",
        buildName: "frontend build"
    )

    static let core = GitHubRepository(
        owner: "home-assistant",
        name: "core",
        displayName: "Core",
        workflowFile: "ci.yaml",
        branch: "dev",
        artifactName: "",
        buildName: "build"
    )
}
