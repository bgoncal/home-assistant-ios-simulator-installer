import Foundation

enum FrontendChannel: String, CaseIterable, Identifiable {
    case release
    case dev
    case pullRequest

    var id: Self { self }

    var label: String {
        switch self {
        case .release: "Latest release"
        case .dev: "Development (dev)"
        case .pullRequest: "A pull request"
        }
    }

    var needsGitHub: Bool { self != .release }

    var shortLabel: String {
        switch self {
        case .release: "release"
        case .dev: "dev"
        case .pullRequest: "pull request"
        }
    }
}
