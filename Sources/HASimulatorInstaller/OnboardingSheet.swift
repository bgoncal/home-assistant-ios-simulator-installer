import SwiftUI

struct OnboardingSheet: View {
    @Bindable var model: InstallerModel
    @State private var step = OnboardingStep.welcome

    var body: some View {
        @Bindable var android = model.android
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Text("\(step.rawValue + 1) of \(OnboardingStep.allCases.count) · \(step.title)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)

            Group {
                switch step {
                case .welcome:
                    OnboardingWelcomeStep()
                case .choose:
                    OnboardingChooseStep(model: model)
                case .setup:
                    OnboardingSetupStep(model: model)
                case .ready:
                    OnboardingReadyStep(model: model)
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            Divider()
            footer
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
        }
        .frame(width: 720, height: 540)
        .interactiveDismissDisabled()
        .sheet(item: $model.deviceCode) { code in
            SignInSheet(model: model, code: code)
        }
        .sheet(isPresented: $model.showsTokenEntry) {
            TokenEntrySheet(model: model)
        }
        .sheet(isPresented: $model.showsRuntimeVersions) {
            RuntimeVersionsSheet(model: model)
        }
        .sheet(isPresented: $android.showsLicense) {
            AndroidLicenseSheet(android: model.android)
        }
    }

    @ViewBuilder
    private var footer: some View {
        HStack {
            switch step {
            case .welcome:
                Text("Takes about a minute")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Skip") { model.completeOnboarding(runNow: false) }
                Button("Get started") { step = .choose }
                    .keyboardShortcut(.defaultAction)
            case .choose:
                Button("Back") { step = .welcome }
                Spacer()
                Button("Continue") { step = .setup }
                    .keyboardShortcut(.defaultAction)
                    .disabled(!(model.iOSEnabled || model.android.enabled || model.server.isActive))
            case .setup:
                Button("Back") { step = .choose }
                Text("You can finish this later in Setup")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if !model.onboardingSetupIsComplete {
                    Button("Skip for Now") { step = .ready }
                }
                Button("Continue") { step = .ready }
                    .keyboardShortcut(.defaultAction)
                    .disabled(!model.onboardingSetupIsComplete)
            case .ready:
                Button("Back") { step = .setup }
                Spacer()
                Button("Explore First") { model.completeOnboarding(runNow: false) }
                Button("Run Now") { model.completeOnboarding(runNow: true) }
                    .keyboardShortcut(.defaultAction)
                    .disabled(!model.canRun)
            }
        }
    }
}

#Preview {
    OnboardingSheet(model: InstallerModel())
}
