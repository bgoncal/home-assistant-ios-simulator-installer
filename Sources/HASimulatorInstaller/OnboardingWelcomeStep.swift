import AppKit
import SwiftUI

struct OnboardingWelcomeStep: View {
    var body: some View {
        VStack(spacing: 14) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 88, height: 88)
            Text("Try Home Assistant on your Mac")
                .font(.title.bold())
            Text("Test builds of the apps, the server and the web interface, without building anything. Pick the latest version or any pull request.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 460)
                .fixedSize(horizontal: false, vertical: true)
            HStack(alignment: .top, spacing: 10) {
                OnboardingPartTile(component: .iOSApp, detail: "In the iOS Simulator")
                OnboardingPartTile(component: .androidApp, detail: "In the emulator, or as an APK")
                OnboardingPartTile(component: .core, detail: "A server on this Mac")
                OnboardingPartTile(component: .frontend, detail: "The web interface")
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    OnboardingWelcomeStep()
        .padding(32)
        .frame(width: 680)
}
