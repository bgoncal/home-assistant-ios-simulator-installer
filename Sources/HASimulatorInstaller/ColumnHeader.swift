import SwiftUI

struct ColumnHeader: View {
    let component: Component
    let detail: String
    let status: ComponentStatus
    @Binding var isOn: Bool
    let isBusy: Bool
    let onInspect: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label {
                    Text(component.title)
                } icon: {
                    ComponentIcon(component: component, size: 15)
                }
                .font(.headline)
                Spacer()
                Toggle(component.title, isOn: $isOn)
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .disabled(isBusy)
            }
            HStack {
                StatusBadge(status: status)
                Spacer()
                Button(action: onInspect) {
                    Image(systemName: "info.circle")
                }
                .buttonStyle(.borderless)
                .help("Show details and logs")
            }
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    ColumnHeader(
        component: .core,
        detail: "The Home Assistant server, running on this Mac",
        status: .running("2026.10.4"),
        isOn: .constant(true),
        isBusy: false,
        onInspect: {}
    )
    .padding()
    .frame(width: 300)
}
