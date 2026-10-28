import SwiftUI

struct ComponentIcon: View {
    let component: Component
    var size: CGFloat = 14

    var body: some View {
        switch component {
        case .iOSApp:
            Image(systemName: "apple.logo")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .accessibilityLabel(component.title)
        case .androidApp:
            AndroidLogo()
                .frame(width: size, height: size)
        case .core, .frontend:
            Image(systemName: component.systemImage)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .accessibilityLabel(component.title)
        }
    }
}

#Preview {
    HStack {
        ForEach(Component.allCases) { component in
            ComponentIcon(component: component)
        }
    }
    .padding()
}
