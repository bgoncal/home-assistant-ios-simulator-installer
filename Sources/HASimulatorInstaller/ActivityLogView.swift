import SwiftUI

struct ActivityLogView: View {
    let entries: [ActivityEntry]

    var body: some View {
        LogTextView(text: entries.map(line).joined(separator: "\n"))
    }

    private func line(_ entry: ActivityEntry) -> String {
        let time = entry.date.formatted(date: .omitted, time: .standard)
        return entry.isError ? "\(time)  ⚠ \(entry.message)" : "\(time)  \(entry.message)"
    }
}

#Preview {
    ActivityLogView(entries: [
        ActivityEntry(date: Date(), component: .core, message: "Installing Python…", isError: false),
        ActivityEntry(date: Date(), component: .core, message: "Couldn't install Home Assistant Core", isError: true),
    ])
    .padding()
    .frame(width: 360)
}
