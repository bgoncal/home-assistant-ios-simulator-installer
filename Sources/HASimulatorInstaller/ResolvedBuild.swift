import Foundation

struct ResolvedBuild: Sendable {
    let artifactID: Int
    let artifactSize: Int
    let title: String
    let commit: String
    let builtAt: Date
}
