import Foundation

struct AndroidEmulatorController: Sendable {
    let sdk: AndroidSDK

    private var environment: [String: String] {
        ["ANDROID_HOME": sdk.root.path, "ANDROID_SDK_ROOT": sdk.root.path]
    }

    func devices() async throws -> [AndroidVirtualDevice] {
        let result = try await ProcessRunner.run(sdk.emulator.path, ["-list-avds"], environment: environment)
        return result.output
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.hasPrefix("INFO") && !$0.contains(" ") }
            .map(AndroidVirtualDevice.init)
    }

    func runningSerial(of device: AndroidVirtualDevice) async throws -> String? {
        let devices = try await adb(["devices"]).output
        for line in devices.split(whereSeparator: \.isNewline) {
            let columns = line.split(whereSeparator: \.isWhitespace)
            guard columns.count == 2, columns[0].hasPrefix("emulator-"), columns[1] == "device" else { continue }
            let serial = String(columns[0])
            let name = try await adb(["-s", serial, "emu", "avd", "name"]).output
                .split(whereSeparator: \.isNewline).first?
                .trimmingCharacters(in: .whitespaces)
            if name == device.name {
                return serial
            }
        }
        return nil
    }

    func boot(_ device: AndroidVirtualDevice) async throws -> String {
        if try await runningSerial(of: device) == nil {
            _ = try ProcessRunner.start(sdk.emulator.path, ["-avd", device.name], environment: environment)
        }

        for _ in 0 ..< 240 {
            if let serial = try await runningSerial(of: device) {
                let booted = try await adb(["-s", serial, "shell", "getprop", "sys.boot_completed"]).output
                if booted.trimmingCharacters(in: .whitespacesAndNewlines) == "1" {
                    return serial
                }
            }
            try await Task.sleep(for: .seconds(1))
        }
        throw InstallerError("\(device.displayName) didn't finish starting up. Close the emulator window and try again.")
    }

    func install(_ apk: URL, on serial: String) async throws {
        let result = try await adb(["-s", serial, "install", "-r", "-d", apk.path])
        guard result.succeeded, result.output.contains("Success") else {
            let message = result.error + result.output
            if message.contains("INSTALL_FAILED_UPDATE_INCOMPATIBLE") {
                throw InstallerError(
                    "The emulator has a copy of the app that was built differently. Turn on Start fresh to replace it (this removes its data)."
                )
            }
            throw InstallerError("Installing the app failed: \(result.lastErrorLine)")
        }
    }

    func uninstall(_ packageName: String, from serial: String) async throws {
        _ = try await adb(["-s", serial, "uninstall", packageName])
    }

    func launch(_ packageName: String, on serial: String) async throws {
        let resolved = try await adb([
            "-s", serial, "shell", "cmd", "package", "resolve-activity", "--brief", "-c", "android.intent.category.LAUNCHER", packageName,
        ])
        guard let component = resolved.output
            .split(whereSeparator: \.isNewline)
            .map({ $0.trimmingCharacters(in: .whitespaces) })
            .last(where: { $0.hasPrefix("\(packageName)/") }) else {
            throw InstallerError("Opening the app failed: Android couldn't find its main screen.")
        }
        let result = try await adb([
            "-s", serial, "shell", "am", "start", "-a", "android.intent.action.MAIN", "-c", "android.intent.category.LAUNCHER", "-n", component,
        ])
        guard result.succeeded, !result.output.contains("Error") else {
            throw InstallerError("Opening the app failed: \(result.lastErrorLine)")
        }
    }

    func stop(_ packageName: String, on serial: String) async throws {
        _ = try await adb(["-s", serial, "shell", "am", "force-stop", packageName])
    }

    func open(_ url: URL, in packageName: String, on serial: String) async throws {
        let result = try await adb([
            "-s", serial, "shell", "am", "start", "-a", "android.intent.action.VIEW", "-d", "'\(url.absoluteString)'", packageName,
        ])
        guard result.succeeded, !result.output.contains("Error") else {
            throw InstallerError("Opening the link in the app failed: \(result.lastErrorLine)")
        }
    }

    func screenshot(of serial: String, to file: URL) async throws {
        let remote = "/sdcard/ha-installer-screenshot.png"
        _ = try await adb(["-s", serial, "shell", "screencap", "-p", remote])
        let result = try await adb(["-s", serial, "pull", remote, file.path])
        _ = try await adb(["-s", serial, "shell", "rm", remote])
        guard result.succeeded else {
            throw InstallerError("Taking the screenshot failed: \(result.lastErrorLine)")
        }
    }

    private func adb(_ arguments: [String]) async throws -> ProcessResult {
        try await ProcessRunner.run(sdk.adb.path, arguments, environment: environment)
    }
}
