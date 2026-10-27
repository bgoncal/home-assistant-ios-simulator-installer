import Foundation

struct SimulatorRuntime: Identifiable, Hashable, Sendable {
    let identifier: String
    let name: String
    let version: String
    let build: String
    let deviceTypes: [SimulatorDeviceType]

    var id: String { identifier }
}
