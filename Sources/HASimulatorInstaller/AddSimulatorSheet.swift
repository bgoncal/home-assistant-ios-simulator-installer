import SwiftUI

struct AddSimulatorSheet: View {
    let model: InstallerModel
    @Environment(\.dismiss) private var dismiss
    @State private var runtimeID: String?
    @State private var typeID: String?
    @State private var name = ""
    @State private var isAdding = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Add a Simulator")
                .font(.title2.bold())

            Form {
                Picker("iOS version", selection: $runtimeID) {
                    ForEach(model.runtimes) { runtime in
                        Text(model.runtimeLabel(runtime)).tag(Optional(runtime.identifier))
                    }
                }
                Picker("Device", selection: $typeID) {
                    ForEach(deviceGroups, id: \.title) { group in
                        Section(group.title) {
                            ForEach(group.types) { type in
                                Text(type.name).tag(Optional(type.identifier))
                            }
                        }
                    }
                }
                TextField("Name", text: $name)
            }
            .formStyle(.grouped)
            .frame(height: 170)

            Button("Download Another iOS Version…") {
                dismiss()
                model.showsRuntimeVersions = true
            }
            .buttonStyle(.link)

            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack {
                if isAdding {
                    ProgressView().controlSize(.small)
                }
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Add") { Task { await add() } }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                    .disabled(isAdding || selectedType == nil || name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 480)
        .onAppear {
            runtimeID = model.selectedRuntimeID ?? model.runtimes.first?.identifier
            selectDefaultType()
        }
        .onChange(of: runtimeID) {
            if selectedType == nil { selectDefaultType() }
        }
        .onChange(of: typeID) { oldValue, _ in
            let oldName = runtime?.deviceTypes.first { $0.identifier == oldValue }?.name
            if name.isEmpty || name == oldName {
                name = selectedType?.name ?? ""
            }
        }
    }

    private var runtime: SimulatorRuntime? {
        model.runtimes.first { $0.identifier == runtimeID }
    }

    private var selectedType: SimulatorDeviceType? {
        runtime?.deviceTypes.first { $0.identifier == typeID }
    }

    private var deviceGroups: [(title: String, types: [SimulatorDeviceType])] {
        let types = runtime?.deviceTypes ?? []
        let phones = types.filter { $0.name.hasPrefix("iPhone") }
        let tablets = types.filter { $0.name.hasPrefix("iPad") }
        let others = types.filter { !$0.name.hasPrefix("iPhone") && !$0.name.hasPrefix("iPad") }
        return [("iPhone", phones), ("iPad", tablets), ("Other", others)].filter { !$0.1.isEmpty }
    }

    private func selectDefaultType() {
        let types = runtime?.deviceTypes ?? []
        let newestPhone = types
            .compactMap { type in type.name.wholeMatch(of: /iPhone (\d+)/).flatMap { Int($0.1) }.map { (type, $0) } }
            .max { $0.1 < $1.1 }?
            .0
        typeID = (newestPhone ?? types.last { $0.name.hasPrefix("iPhone") } ?? types.first)?.identifier
        name = selectedType?.name ?? ""
    }

    private func add() async {
        guard let runtime, let type = selectedType else { return }
        isAdding = true
        errorMessage = nil
        do {
            try await model.addSimulator(type, runtime: runtime, name: name.trimmingCharacters(in: .whitespaces))
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isAdding = false
    }
}

#Preview {
    AddSimulatorSheet(model: InstallerModel())
}
