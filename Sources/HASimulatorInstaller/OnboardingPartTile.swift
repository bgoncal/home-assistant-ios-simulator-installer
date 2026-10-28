import SwiftUI

struct OnboardingPartTile: View {
    let component: Component
    let detail: String
    var isSelected: Bool?

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            ComponentIcon(component: component, size: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(component.title)
                    .font(.headline)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            if let isSelected {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected == true ? Color.accentColor.opacity(0.08) : Color.clear)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(isSelected == true ? Color.accentColor : Color.secondary.opacity(0.3), lineWidth: isSelected == true ? 2 : 0.5)
        }
        .contentShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    HStack {
        OnboardingPartTile(component: .iOSApp, detail: "In the iOS Simulator")
        OnboardingPartTile(component: .core, detail: "Nothing to install", isSelected: true)
        OnboardingPartTile(component: .androidApp, detail: "Sets up an emulator", isSelected: false)
    }
    .padding()
    .frame(width: 640)
}
