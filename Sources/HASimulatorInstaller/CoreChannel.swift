import Foundation

enum CoreChannel: String, CaseIterable, Identifiable {
    case release
    case beta
    case dev
    case pullRequest

    var id: Self { self }

    var label: String {
        switch self {
        case .release: "Latest release"
        case .beta: "Beta"
        case .dev: "Development (dev)"
        case .pullRequest: "A pull request"
        }
    }

    var shortLabel: String {
        switch self {
        case .release: "release"
        case .beta: "beta"
        case .dev: "dev"
        case .pullRequest: "pull request"
        }
    }
}
