import AppKit
import SwiftUI

struct AddressRow: View {
    let title: String
    let url: URL

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack {
                Text(url.absoluteString)
                    .font(.body.monospaced())
                    .textSelection(.enabled)
                Spacer()
                Button("Copy") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(url.absoluteString, forType: .string)
                }
                Button("Open in Browser") { NSWorkspace.shared.open(url) }
            }
        }
    }
}

#Preview {
    AddressRow(title: "On this Mac and in the Simulator", url: URL(string: "http://localhost:8123")!)
        .padding()
        .frame(width: 600)
}
