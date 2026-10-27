import Foundation

struct AppUpdate: Equatable, Sendable {
    let version: String
    let notes: String
    let downloadURL: URL
    let sha256: String?
    let pageURL: URL
}
