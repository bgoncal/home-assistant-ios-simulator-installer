import Foundation

enum InstallPhase: Equatable {
    case idle
    case working(String, progress: Double?)
    case done(String)

    var isWorking: Bool {
        if case .working = self { return true }
        return false
    }
}
