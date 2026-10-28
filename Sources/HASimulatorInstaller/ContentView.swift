import SwiftUI

struct ContentView: View {
    @Bindable var model: InstallerModel
    let updater: Updater

    @State private var selection: SidebarItem? = .run
    @State private var showsInspector = true
    @State private var inspected: Component = .core

    var body: some View {
        @Bindable var android = model.android
        NavigationSplitView {
            SidebarView(model: model, selection: $selection)
                .navigationSplitViewColumnWidth(min: 180, ideal: 210, max: 280)
        } detail: {
            Group {
                switch selection {
                case .setup:
                    SetupPage(model: model, updater: updater)
                case .downloads:
                    DownloadsPage(model: model)
                default:
                    RunPage(model: model, updater: updater, onInspect: inspect)
                }
            }
            .inspector(isPresented: $showsInspector) {
                InspectorView(model: model, component: $inspected)
                    .inspectorColumnWidth(min: 300, ideal: 360, max: 560)
            }
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button { Task { await model.stop() } } label: {
                        Label("Stop", systemImage: "stop.fill")
                    }
                    .keyboardShortcut(".", modifiers: .command)
                    .disabled(!model.canStop)
                    .help("Stop (⌘.)")

                    Button { model.run() } label: {
                        Label("Run", systemImage: "play.fill")
                    }
                    .keyboardShortcut("r", modifiers: .command)
                    .disabled(!model.canRun)
                    .help("Run (⌘R)")

                    Button { showsInspector.toggle() } label: {
                        Label("Inspector", systemImage: "sidebar.trailing")
                    }
                    .help("Show or hide details and logs")
                }
            }
        }
        .onChange(of: selection) {
            guard case let .recent(id) = selection else { return }
            if let run = model.recentRuns.run(withID: id) {
                model.apply(run.selection)
            } else {
                selection = .run
            }
        }
        .onChange(of: model.recentRuns.runs) {
            if case let .recent(id) = selection, model.recentRuns.run(withID: id) == nil {
                selection = .run
            }
        }
        .frame(minWidth: 1100, minHeight: 640)
        .task { model.showOnboardingIfNeeded() }
        .task { await model.refreshSetup() }
        .task { await model.server.stopLeftoverServer() }
        .task { await updater.check(userInitiated: false) }
        .sheet(item: $model.deviceCode) { code in
            SignInSheet(model: model, code: code)
        }
        .sheet(isPresented: $model.showsTokenEntry) {
            TokenEntrySheet(model: model)
        }
        .sheet(isPresented: $model.showsXcodeVersions) {
            XcodeVersionsSheet(model: model)
        }
        .sheet(isPresented: $model.showsRuntimeVersions) {
            RuntimeVersionsSheet(model: model)
        }
        .sheet(isPresented: $android.showsLicense) {
            AndroidLicenseSheet(android: model.android)
        }
        .sheet(isPresented: $android.showsAddDevice) {
            AddEmulatorSheet(android: model.android)
        }
        .sheet(isPresented: $model.showsAddSimulator) {
            AddSimulatorSheet(model: model)
        }
        .sheet(isPresented: $model.showsOnboarding) {
            OnboardingSheet(model: model)
        }
    }

    private func inspect(_ component: Component) {
        inspected = component
        showsInspector = true
    }
}

#Preview {
    ContentView(model: InstallerModel(), updater: Updater())
        .frame(width: 1400, height: 850)
}
