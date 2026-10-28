import Foundation
import Observation

@MainActor
@Observable
final class ActivityLog {
    private static let limit = 500

    private(set) var entries: [ActivityEntry] = []

    func add(_ message: String, for component: Component, isError: Bool = false) {
        if let last = entries.last(where: { $0.component == component }), last.message == message, last.isError == isError {
            return
        }
        entries.append(ActivityEntry(date: Date(), component: component, message: message, isError: isError))
        if entries.count > Self.limit {
            entries.removeFirst(entries.count - Self.limit)
        }
    }

    func entries(for component: Component) -> [ActivityEntry] {
        entries.filter { $0.component == component }
    }
}
