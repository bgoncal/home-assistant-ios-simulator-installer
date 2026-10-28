import Foundation

struct RecentRun: Codable, Identifiable, Hashable {
    var id = UUID()
    var date: Date
    var selection: RunSelection
}
