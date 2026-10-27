// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "HASimulatorInstaller",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "HASimulatorInstaller",
            path: "Sources/HASimulatorInstaller"
        ),
    ]
)
