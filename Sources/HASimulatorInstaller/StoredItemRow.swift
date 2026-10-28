import SwiftUI

struct StoredItemRow: View {
    let item: StoredItem
    let isInUse: Bool
    let onDelete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .lineLimit(1)
                    .truncationMode(.middle)
                if let date = item.date {
                    Text(isInUse ? "In use · last used \(date.formatted(.relative(presentation: .named)))" : "Last used \(date.formatted(.relative(presentation: .named)))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text(item.size.formatted(.byteCount(style: .file)))
                .monospacedDigit()
                .foregroundStyle(.secondary)
            Button("Delete", action: onDelete)
                .disabled(isInUse)
                .help(isInUse ? "In use by the running server" : "Delete from this Mac")
        }
    }
}

#Preview {
    Form {
        StoredItemRow(
            item: StoredItem(url: URL(fileURLWithPath: "/tmp/a"), title: "2026.10.4", date: Date(), size: 1_200_000_000),
            isInUse: true,
            onDelete: {}
        )
    }
    .formStyle(.grouped)
    .frame(width: 600)
}
