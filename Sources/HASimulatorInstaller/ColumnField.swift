import SwiftUI

struct ColumnField<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            content()
                .labelsHidden()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    ColumnField(title: "Version") {
        Picker("Version", selection: .constant(1)) {
            Text("Latest release").tag(1)
        }
    }
    .padding()
    .frame(width: 240)
}
