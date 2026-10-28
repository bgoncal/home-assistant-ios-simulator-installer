import SwiftUI

struct LogTextView: View {
    let text: String

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text(text.isEmpty ? "Nothing yet." : text)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(text.isEmpty ? .secondary : .primary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Color.clear
                        .frame(height: 1)
                        .id(bottomID)
                }
                .padding(8)
            }
            .frame(minHeight: 260)
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 6))
            .onAppear { proxy.scrollTo(bottomID, anchor: .bottom) }
            .onChange(of: text) { proxy.scrollTo(bottomID, anchor: .bottom) }
        }
    }

    private let bottomID = "bottom"
}

#Preview {
    LogTextView(text: "12:00:01 Finding Home Assistant Core…\n12:00:02 Installing Python…")
        .padding()
        .frame(width: 360)
}
