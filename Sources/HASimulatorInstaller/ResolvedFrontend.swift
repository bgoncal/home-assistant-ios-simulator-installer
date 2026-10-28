import Foundation

enum ResolvedFrontend: Sendable {
    case artifact(ResolvedBuild)
    case release(tag: String, wheel: URL, size: Int)

    var title: String {
        switch self {
        case let .artifact(build): "\(build.title) (\(build.commit))"
        case let .release(tag, _, _): tag
        }
    }

    var cacheKey: String {
        switch self {
        case let .artifact(build): "artifact-\(build.artifactID)"
        case let .release(tag, _, _): "release-\(tag)"
        }
    }
}
