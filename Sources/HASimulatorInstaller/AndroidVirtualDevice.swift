import Foundation

struct AndroidVirtualDevice: Hashable, Identifiable, Sendable {
    let name: String

    var id: String { name }

    var displayName: String {
        name == Constants.androidVirtualDeviceName ? "Home Assistant Test" : name.replacingOccurrences(of: "_", with: " ")
    }
}
