import Foundation

enum DeviceChoice: Hashable, Sendable {
    case existing(SimulatorDevice)
    case new(SimulatorDeviceType)

    var label: String {
        switch self {
        case let .existing(device): device.name
        case let .new(type): "\(type.name) (new)"
        }
    }
}
