import SwiftUI

struct OnboardingReadyStep: View {
    let model: InstallerModel

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: model.canRun ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .font(.system(size: 52))
                .foregroundStyle(model.canRun ? .green : .orange)
            Text(model.canRun ? "You're all set" : "Almost there")
                .font(.title2.bold())
            Text(model.canRun
                ? "Run the latest versions now, or change versions and pull requests first."
                : "Some setup is still missing. You can finish it in Setup, then click Run.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 10) {
                if model.iOSEnabled {
                    row(.iOSApp, detail: "Latest on \(model.deviceChoice?.label ?? "a new simulator")")
                }
                if model.android.enabled {
                    row(.androidApp, detail: "Latest \(model.android.flavor.label.lowercased()) on \(model.android.device?.displayName ?? "the emulator")")
                }
                if model.server.isActive {
                    row(.core, detail: model.server.coreEnabled ? model.server.coreChannel.label : "Latest release")
                }
                if model.server.frontendEnabled {
                    row(.frontend, detail: model.server.frontendChannel.label)
                }
            }
            .padding(14)
            .frame(minWidth: 340)
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 10))

            if model.server.isActive, model.iOSEnabled || model.android.enabled {
                Text("When an app and Core run together, the app is connected to the server for you.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func row(_ component: Component, detail: String) -> some View {
        HStack(spacing: 10) {
            ComponentIcon(component: component, size: 16)
            Text(component.title)
            Spacer(minLength: 24)
            Text(detail)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    OnboardingReadyStep(model: InstallerModel())
        .padding(32)
        .frame(width: 680)
}
