import Foundation

struct RunningServer: Equatable {
    let port: Int
    let networkAddress: String?
    let coreTitle: String
    let frontendTitle: String?
    let coreKey: String
    let frontendKey: String?
    let frontendDirectory: URL?

    var localURL: URL { URL(string: "http://localhost:\(port)")! }

    var networkURL: URL? {
        networkAddress.flatMap { URL(string: "http://\($0):\(port)") }
    }

    var summary: String {
        let core = "Core \(coreTitle)"
        guard let frontendTitle else { return core }
        return "\(core) · Frontend \(frontendTitle)"
    }
}
