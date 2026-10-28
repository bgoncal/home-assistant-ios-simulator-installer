import Foundation
import Observation

@MainActor
@Observable
final class RecentRuns {
    private static let key = "recentRuns"
    private static let limit = 10

    private(set) var runs: [RecentRun]

    init() {
        let data = UserDefaults.standard.data(forKey: Self.key)
        runs = data.flatMap { try? JSONDecoder().decode([RecentRun].self, from: $0) } ?? []
    }

    func record(_ selection: RunSelection) {
        let id = runs.first { $0.selection == selection }?.id ?? UUID()
        runs.removeAll { $0.id == id }
        runs.insert(RecentRun(id: id, date: Date(), selection: selection), at: 0)
        runs = Array(runs.prefix(Self.limit))
        save()
    }

    func run(withID id: UUID) -> RecentRun? {
        runs.first { $0.id == id }
    }

    func remove(_ id: UUID) {
        runs.removeAll { $0.id == id }
        save()
    }

    func removeAll() {
        runs = []
        save()
    }

    private func save() {
        UserDefaults.standard.set(try? JSONEncoder().encode(runs), forKey: Self.key)
    }
}
