import Foundation

enum CorePackage: Sendable {
    case pyPI(version: String, requiresPython: String)
    case source(archive: URL)
}
