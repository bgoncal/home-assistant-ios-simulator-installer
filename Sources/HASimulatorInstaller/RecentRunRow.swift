import SwiftUI

struct RecentRunRow: View {
    let run: RecentRun

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(run.date.formatted(date: .abbreviated, time: .shortened))
            HStack(spacing: 7) {
                ForEach(run.selection.parts, id: \.component) { part in
                    ComponentIcon(component: part.component, size: 13)
                        .help(part.component.title)
                }
            }
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
        .help(run.selection.title)
    }
}

#Preview {
    List {
        RecentRunRow(run: RecentRun(
            date: Date().addingTimeInterval(-3600),
            selection: RunSelection(
                iOSEnabled: true,
                iOSPullRequest: 6142,
                coreEnabled: true,
                coreChannelValue: "dev",
                corePullRequest: nil,
                frontendEnabled: true,
                frontendChannelValue: "pullRequest",
                frontendPullRequest: 25000
            )
        ))
    }
    .listStyle(.sidebar)
    .frame(width: 220, height: 200)
}
