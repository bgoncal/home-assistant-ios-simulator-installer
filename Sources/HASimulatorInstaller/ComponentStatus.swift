import SwiftUI

enum ComponentStatus: Equatable {
    case off
    case ready
    case working(String)
    case running(String)
    case failed(String)

    var label: String {
        switch self {
        case .off: "Off"
        case .ready: "Not running"
        case .working: "Working"
        case .running: "Running"
        case .failed: "Failed"
        }
    }

    var detail: String? {
        switch self {
        case .off, .ready: nil
        case let .working(detail), let .running(detail), let .failed(detail): detail
        }
    }

    var color: Color {
        switch self {
        case .off, .ready: .secondary
        case .working: .blue
        case .running: .green
        case .failed: .red
        }
    }
}
