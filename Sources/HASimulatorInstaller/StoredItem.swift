import Foundation

struct StoredItem: Identifiable, Hashable, Sendable {
    let url: URL
    let title: String
    let date: Date?
    let size: Int64

    var id: URL { url }
}
