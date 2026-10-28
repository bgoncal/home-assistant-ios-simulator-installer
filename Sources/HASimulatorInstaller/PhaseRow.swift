import SwiftUI

struct PhaseRow: View {
    let title: String
    let message: String
    let progress: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(title): \(message)")
            if let progress {
                ProgressView(value: progress)
            } else {
                ProgressView().progressViewStyle(.linear)
            }
        }
    }
}

#Preview {
    PhaseRow(title: "Server", message: "Installing Home Assistant Core…", progress: nil)
        .padding()
        .frame(width: 500)
}
