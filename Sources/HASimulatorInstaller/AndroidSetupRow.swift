import SwiftUI

struct AndroidSetupRow: View {
    let android: AndroidModel

    var body: some View {
        SetupRow(title: "Android emulator", detail: detail, isDone: android.isReady) {
            if android.isCheckingSetup {
                ProgressView().controlSize(.small)
            } else if !android.isReady {
                Button("Set Up…") { android.setUpEmulator() }
                    .disabled(android.activity != nil)
            } else if !android.hasTestDevice {
                Button("Add Test Device…") { android.setUpEmulator() }
                    .disabled(android.activity != nil)
            } else {
                Button("Add Emulator…") { android.showsAddDevice = true }
                    .disabled(android.activity != nil)
            }
        }

        if let activity = android.activity {
            ActivityRow(activity: activity) { android.cancelSetup() }
        }
    }

    private var detail: String {
        guard let sdk = android.sdk, sdk.hasEmulator else {
            return "Only needed for the Android app. A one-time download of a few gigabytes."
        }
        guard !android.devices.isEmpty else {
            return "Found the Android SDK in \(sdk.root.path), but no virtual device."
        }
        return android.devices.map(\.displayName).joined(separator: ", ")
    }
}

#Preview {
    Form {
        AndroidSetupRow(android: AndroidModel(activityLog: ActivityLog()))
    }
    .formStyle(.grouped)
    .frame(width: 600)
}
