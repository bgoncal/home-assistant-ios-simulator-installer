import Foundation

enum AndroidFlavor: String, CaseIterable, Identifiable {
    case full
    case minimal

    var id: Self { self }

    var label: String {
        switch self {
        case .full: "Full"
        case .minimal: "Minimal"
        }
    }

    var detail: String {
        switch self {
        case .full: "The Play Store version, with Google services such as notifications"
        case .minimal: "Without Google services, like the F-Droid version"
        }
    }

    func packageName(isDebug: Bool) -> String {
        let base = self == .full ? "io.homeassistant.companion.android" : "io.homeassistant.companion.android.minimal"
        return isDebug ? "\(base).debug" : base
    }
}
