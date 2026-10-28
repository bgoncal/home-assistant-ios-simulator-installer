import SwiftUI

struct AddEmulatorSheet: View {
    let android: AndroidModel
    @Environment(\.dismiss) private var dismiss
    @State private var profile = AndroidDeviceProfile.standard
    @State private var version = AndroidVersion.standard
    @State private var name = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Add an Emulator")
                .font(.title2.bold())

            Form {
                Picker("Device", selection: $profile) {
                    Section("Phones") {
                        ForEach(AndroidDeviceProfile.all.filter { !$0.isTablet }) { profile in
                            Text(profile.name).tag(profile)
                        }
                    }
                    Section("Tablets") {
                        ForEach(AndroidDeviceProfile.all.filter(\.isTablet)) { profile in
                            Text(profile.name).tag(profile)
                        }
                    }
                }
                Picker("Android version", selection: $version) {
                    ForEach(AndroidVersion.all) { version in
                        Text(android.isInstalled(version) ? version.name : "\(version.name) (downloads about 2 GB)")
                            .tag(version)
                    }
                }
                TextField("Name", text: $name)
            }
            .formStyle(.grouped)
            .frame(height: 170)

            if android.hasDevice(named: name) {
                Label("An emulator with this name already exists.", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
            } else {
                Text("The emulator is created in the background. You can follow along in the Android column.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Add") {
                    android.addDevice(named: name, profile: profile, version: version)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || android.hasDevice(named: name) || android.activity != nil)
            }
        }
        .padding(24)
        .frame(width: 480)
        .onAppear { name = defaultName(profile: profile, version: version) }
        .onChange(of: profile) { oldValue, newValue in
            if name == defaultName(profile: oldValue, version: version) {
                name = defaultName(profile: newValue, version: version)
            }
        }
        .onChange(of: version) { oldValue, newValue in
            if name == defaultName(profile: profile, version: oldValue) {
                name = defaultName(profile: profile, version: newValue)
            }
        }
    }

    private func defaultName(profile: AndroidDeviceProfile, version: AndroidVersion) -> String {
        "\(profile.name) \(version.name)"
    }
}

#Preview {
    AddEmulatorSheet(android: AndroidModel(activityLog: ActivityLog()))
}
