import Foundation

enum OnboardingStep: Int, CaseIterable {
    case welcome
    case choose
    case setup
    case ready

    var title: String {
        switch self {
        case .welcome: "Welcome"
        case .choose: "What to test"
        case .setup: "Setup"
        case .ready: "Ready"
        }
    }
}
