import SwiftUI

struct AndroidLicenseSheet: View {
    let android: AndroidModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Set up the Android emulator")
                .font(.title2.bold())
            Text("This downloads Google's Android SDK tools, an Android system image and Java, a few gigabytes in all, and creates a virtual phone named Home Assistant Test.")
                .fixedSize(horizontal: false, vertical: true)
            Text("To use them, you need to accept Google's Android Software Development Kit License Agreement.")
                .fixedSize(horizontal: false, vertical: true)
            Link("Read the License Agreement", destination: AndroidSDKInstaller.licenseURL)
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Accept and Install") { android.acceptLicenseAndSetUp() }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 460)
    }
}

#Preview {
    AndroidLicenseSheet(android: AndroidModel(activityLog: ActivityLog()))
}
