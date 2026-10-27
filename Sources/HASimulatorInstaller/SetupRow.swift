import SwiftUI

struct SetupRow<Action: View>: View {
    let title: String
    let detail: String
    let isDone: Bool
    @ViewBuilder let action: () -> Action

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isDone ? .green : .secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            action()
        }
    }
}

#Preview {
    Form {
        SetupRow(title: "Xcode", detail: "Installed", isDone: true) { EmptyView() }
        SetupRow(title: "GitHub", detail: "Needed to download builds", isDone: false) {
            Button("Sign In") {}
        }
    }
    .formStyle(.grouped)
}
