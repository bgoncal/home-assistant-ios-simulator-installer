import SwiftUI

struct InspectorStatusSection: View {
    let status: ComponentStatus

    var body: some View {
        Section("Status") {
            StatusBadge(status: status)
            if let detail = status.detail {
                Text(detail)
                    .font(.callout)
                    .foregroundStyle(status == .failed(detail) ? .red : .secondary)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    Form {
        InspectorStatusSection(status: .failed("Home Assistant stopped while starting."))
    }
    .formStyle(.grouped)
    .frame(width: 340)
}
