import SwiftUI

struct ActivityRow: View {
    let activity: Activity
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(activity.title)
                Spacer()
                Button("Cancel", action: onCancel)
            }
            if let progress = activity.progress {
                ProgressView(value: progress)
            } else {
                ProgressView().progressViewStyle(.linear)
            }
            if let detail = activity.detail {
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    Form {
        ActivityRow(
            activity: Activity(title: "Downloading iOS 26.5", detail: "Using Xcode 27.1 (27A9275).", progress: 0.4)
        ) {}
    }
    .formStyle(.grouped)
}
