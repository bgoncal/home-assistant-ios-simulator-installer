import SwiftUI

struct StartFreshToggle: View {
    let detail: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Start fresh")
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .toggleStyle(.checkbox)
    }
}

#Preview {
    StartFreshToggle(detail: "Removes the app and its data first", isOn: .constant(false))
        .padding()
        .frame(width: 240)
}
