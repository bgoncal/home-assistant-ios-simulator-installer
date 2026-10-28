import SwiftUI

struct SidebarView: View {
    let model: InstallerModel
    @Binding var selection: SidebarItem?

    var body: some View {
        List(selection: $selection) {
            Section {
                Label("Run", systemImage: "play.circle")
                    .tag(SidebarItem.run)
                HStack {
                    Label("Setup", systemImage: "wrench.and.screwdriver")
                    Spacer()
                    if model.isCheckingSetup {
                        ProgressView().controlSize(.mini)
                    } else if !model.isReady {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(.orange)
                            .help("Setup isn't finished. The iOS app needs it.")
                    }
                }
                .tag(SidebarItem.setup)
                Label("Downloads", systemImage: "internaldrive")
                    .tag(SidebarItem.downloads)
            }

            Section("Recent") {
                if model.recentRuns.runs.isEmpty {
                    Text("What you run shows up here, so you can pick it again.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                ForEach(model.recentRuns.runs) { run in
                    RecentRunRow(run: run)
                        .tag(SidebarItem.recent(run.id))
                        .contextMenu {
                            Button("Run Again") {
                                model.apply(run.selection)
                                model.run()
                            }
                            .disabled(model.isBusy)
                            Button("Remove from Recent") { model.recentRuns.remove(run.id) }
                            Divider()
                            Button("Clear Recent") { model.recentRuns.removeAll() }
                        }
                }
            }
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .bottom) {
            Button { model.showsOnboarding = true } label: {
                Label("Onboard again", systemImage: "sparkles")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.borderless)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
}

#Preview {
    SidebarView(model: InstallerModel(), selection: .constant(.run))
        .frame(width: 220, height: 500)
}
