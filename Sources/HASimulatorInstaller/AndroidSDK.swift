import Foundation

struct AndroidSDK: Equatable, Sendable {
    let root: URL

    var adb: URL { root.appendingPathComponent("platform-tools/adb") }
    var emulator: URL { root.appendingPathComponent("emulator/emulator") }
    var sdkManager: URL { root.appendingPathComponent("cmdline-tools/latest/bin/sdkmanager") }
    var avdManager: URL { root.appendingPathComponent("cmdline-tools/latest/bin/avdmanager") }

    var hasEmulator: Bool {
        FileManager.default.isExecutableFile(atPath: emulator.path) && FileManager.default.isExecutableFile(atPath: adb.path)
    }

    var hasCommandLineTools: Bool {
        FileManager.default.isExecutableFile(atPath: sdkManager.path)
    }

    var hasAcceptedLicense: Bool {
        FileManager.default.fileExists(atPath: root.appendingPathComponent("licenses/android-sdk-license").path)
    }

    var installedSystemImages: [String] {
        let images = root.appendingPathComponent("system-images")
        let levels = (try? FileManager.default.contentsOfDirectory(atPath: images.path)) ?? []
        return levels.flatMap { level in
            let tags = (try? FileManager.default.contentsOfDirectory(atPath: images.appendingPathComponent(level).path)) ?? []
            return tags.flatMap { tag in
                let abis = (try? FileManager.default.contentsOfDirectory(
                    atPath: images.appendingPathComponent(level).appendingPathComponent(tag).path
                )) ?? []
                return abis.filter { !$0.hasPrefix(".") }.map { "system-images;\(level);\(tag);\($0)" }
            }
        }
    }

    static func locate() -> AndroidSDK? {
        let environment = ProcessInfo.processInfo.environment
        let home = FileManager.default.homeDirectoryForCurrentUser
        let candidates = ([environment["ANDROID_HOME"], environment["ANDROID_SDK_ROOT"]].compactMap { $0 }.map { URL(fileURLWithPath: $0) }
            + [home.appendingPathComponent("Library/Android/sdk"), Constants.managedAndroidSDKDirectory])
            .map(AndroidSDK.init)
        return candidates.first(where: \.hasEmulator)
            ?? candidates.first { FileManager.default.fileExists(atPath: $0.root.path) }
    }
}
