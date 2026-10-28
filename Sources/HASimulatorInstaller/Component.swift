import Foundation

enum Component: String, CaseIterable, Identifiable, Hashable {
    case iOSApp
    case androidApp
    case core
    case frontend

    var id: Self { self }

    var title: String {
        switch self {
        case .iOSApp: "iOS app"
        case .androidApp: "Android app"
        case .core: "Core"
        case .frontend: "Frontend"
        }
    }

    var shortTitle: String {
        switch self {
        case .iOSApp: "iOS"
        case .androidApp: "Android"
        case .core: "Core"
        case .frontend: "Frontend"
        }
    }

    var systemImage: String {
        switch self {
        case .iOSApp: "iphone"
        case .androidApp: "candybarphone"
        case .core: "server.rack"
        case .frontend: "macwindow"
        }
    }
}
