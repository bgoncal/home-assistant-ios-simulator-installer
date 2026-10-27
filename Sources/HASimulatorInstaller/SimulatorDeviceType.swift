import Foundation

struct SimulatorDeviceType: Identifiable, Hashable, Sendable {
    let identifier: String
    let name: String

    var id: String { identifier }
}
