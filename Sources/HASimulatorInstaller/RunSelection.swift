import Foundation

struct RunSelection: Codable, Hashable {
    var iOSEnabled: Bool
    var iOSPullRequest: Int?
    var coreEnabled: Bool
    var coreChannelValue: String
    var corePullRequest: Int?
    var frontendEnabled: Bool
    var frontendChannelValue: String
    var frontendPullRequest: Int?

    var coreChannel: CoreChannel { CoreChannel(rawValue: coreChannelValue) ?? .release }
    var frontendChannel: FrontendChannel { FrontendChannel(rawValue: frontendChannelValue) ?? .dev }

    var parts: [(component: Component, label: String)] {
        var parts: [(Component, String)] = []
        if iOSEnabled {
            parts.append((.iOSApp, iOSPullRequest.map { "#\($0)" } ?? "latest"))
        }
        if coreEnabled {
            parts.append((.core, coreChannel == .pullRequest ? corePullRequest.map { "#\($0)" } ?? "Pull request" : coreChannel.shortLabel))
        }
        if frontendEnabled {
            parts.append((.frontend, frontendChannel == .pullRequest ? frontendPullRequest.map { "#\($0)" } ?? "Pull request" : frontendChannel.shortLabel))
        }
        return parts
    }

    var title: String {
        parts.map { "\($0.component.title) \($0.label)" }.joined(separator: " · ")
    }
}
