import Foundation

enum Component: String, CaseIterable, Identifiable, Hashable {
    case iOSApp
    case core
    case frontend

    var id: Self { self }

    var title: String {
        switch self {
        case .iOSApp: "iOS app"
        case .core: "Core"
        case .frontend: "Frontend"
        }
    }

    var systemImage: String {
        switch self {
        case .iOSApp: "iphone"
        case .core: "server.rack"
        case .frontend: "macwindow"
        }
    }
}
