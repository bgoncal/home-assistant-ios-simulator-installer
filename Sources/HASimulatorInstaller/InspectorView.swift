import SwiftUI

struct InspectorView: View {
    let model: InstallerModel
    @Binding var component: Component

    var body: some View {
        VStack(spacing: 0) {
            Picker("Component", selection: $component) {
                ForEach(Component.allCases) { component in
                    Text(component.title).tag(component)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(10)

            Divider()

            switch component {
            case .iOSApp:
                IOSInspector(model: model)
            case .core:
                CoreInspector(model: model)
            case .frontend:
                FrontendInspector(model: model)
            }
        }
    }
}

#Preview {
    InspectorView(model: InstallerModel(), component: .constant(.core))
        .frame(width: 360, height: 800)
}
