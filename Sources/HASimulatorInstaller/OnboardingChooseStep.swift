import SwiftUI

struct OnboardingChooseStep: View {
    @Bindable var model: InstallerModel

    var body: some View {
        @Bindable var server = model.server
        @Bindable var android = model.android
        VStack(alignment: .leading, spacing: 6) {
            Text("What do you want to test?")
                .font(.title2.bold())
            Text("Pick one or more. You can change this anytime.")
                .foregroundStyle(.secondary)
                .padding(.bottom, 10)
            Grid(horizontalSpacing: 10, verticalSpacing: 10) {
                GridRow {
                    tile(.iOSApp, detail: "Needs Xcode", isOn: $model.iOSEnabled)
                    tile(.androidApp, detail: "Sets up an emulator, or just get the APK", isOn: $android.enabled)
                }
                GridRow {
                    tile(.core, detail: "Nothing to install", isOn: $server.coreEnabled)
                    tile(.frontend, detail: "Runs on Core", isOn: $server.frontendEnabled)
                }
            }
        }
    }

    private func tile(_ component: Component, detail: String, isOn: Binding<Bool>) -> some View {
        OnboardingPartTile(component: component, detail: detail, isSelected: isOn.wrappedValue)
            .onTapGesture { isOn.wrappedValue.toggle() }
            .accessibilityAddTraits(.isButton)
            .accessibilityValue(isOn.wrappedValue ? "Selected" : "Not selected")
    }
}

#Preview {
    OnboardingChooseStep(model: InstallerModel())
        .padding(32)
        .frame(width: 680)
}
