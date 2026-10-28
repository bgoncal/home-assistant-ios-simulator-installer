import SwiftUI

struct StatusBadge: View {
    let status: ComponentStatus
    var isCompact = false

    var body: some View {
        HStack(spacing: 4) {
            if case .working = status {
                ProgressView()
                    .controlSize(.mini)
            } else {
                Circle()
                    .fill(status.color)
                    .frame(width: 7, height: 7)
            }
            if !isCompact {
                Text(status.label)
                    .font(.caption.weight(.medium))
            }
        }
        .foregroundStyle(status.color)
        .padding(.horizontal, isCompact ? 0 : 7)
        .padding(.vertical, isCompact ? 0 : 2)
        .background {
            if !isCompact {
                Capsule().fill(status.color.opacity(0.15))
            }
        }
        .help(status.detail ?? status.label)
    }
}

#Preview {
    VStack(alignment: .leading) {
        StatusBadge(status: .off)
        StatusBadge(status: .ready)
        StatusBadge(status: .working("Installing…"))
        StatusBadge(status: .running("2026.10.4"))
        StatusBadge(status: .failed("Something went wrong"))
        StatusBadge(status: .running("2026.10.4"), isCompact: true)
    }
    .padding()
}
