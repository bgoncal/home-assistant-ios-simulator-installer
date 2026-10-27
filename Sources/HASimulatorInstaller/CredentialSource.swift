import Foundation

enum CredentialSource: Equatable, Sendable {
    case stored
    case gitHubCLI(String)
    case signedOut

    init?(rawValue: String) {
        switch rawValue {
        case "stored": self = .stored
        case "signedOut": self = .signedOut
        default:
            guard rawValue.hasPrefix("gh:") else { return nil }
            self = .gitHubCLI(String(rawValue.dropFirst(3)))
        }
    }

    var rawValue: String {
        switch self {
        case .stored: "stored"
        case let .gitHubCLI(login): "gh:\(login)"
        case .signedOut: "signedOut"
        }
    }
}
