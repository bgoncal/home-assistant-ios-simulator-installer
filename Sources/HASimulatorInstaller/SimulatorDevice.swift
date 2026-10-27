import Foundation

struct SimulatorDevice: Identifiable, Hashable, Sendable {
    let udid: String
    let name: String
    let runtimeID: String
    let isBooted: Bool

    var id: String { udid }
    var isPhone: Bool { name.hasPrefix("iPhone") }

    static func == (lhs: SimulatorDevice, rhs: SimulatorDevice) -> Bool {
        lhs.udid == rhs.udid
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(udid)
    }
}
