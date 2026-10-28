import Foundation

enum StorageGroup: CaseIterable, Identifiable {
    case iOSBuilds
    case androidBuilds
    case coreInstalls
    case frontendBuilds
    case tools

    var id: Self { self }

    var title: String {
        switch self {
        case .iOSBuilds: "iOS app builds"
        case .androidBuilds: "Android app builds"
        case .coreInstalls: "Core installs"
        case .frontendBuilds: "Frontend builds"
        case .tools: "Tools"
        }
    }

    var detail: String {
        switch self {
        case .iOSBuilds: "The last three are kept, so installing one again is quick."
        case .androidBuilds: "The last three are kept. The Android emulator and its system image stay in the Android SDK."
        case .coreInstalls: "The last two are kept. Each holds Python packages for one version of Core."
        case .frontendBuilds: "The last three are kept."
        case .tools: "uv and Python, used to install and run Core, and Java when the Android tools need it. Downloaded again when needed."
        }
    }

    var directory: URL {
        switch self {
        case .iOSBuilds: Constants.iOSBuildsDirectory
        case .androidBuilds: Constants.androidBuildsDirectory
        case .coreInstalls: Constants.coreBuildsDirectory
        case .frontendBuilds: Constants.frontendBuildsDirectory
        case .tools: Constants.toolsDirectory
        }
    }
}
