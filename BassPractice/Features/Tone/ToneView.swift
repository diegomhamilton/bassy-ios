import SwiftUI

struct ToneView: View {
    @State private var model: ToneModel

    init(controller: any AudioGainControlling) {
        _model = State(initialValue: ToneModel(controller: controller))
    }

    var body: some View {
        Form {
            GainSection(title: "Input Gain", configuration: model.input, isBusy: model.isBusy) {
                await model.update($0, stage: .input)
                return model.input
            }
            GainSection(title: "Output Gain", configuration: model.output, isBusy: model.isBusy) {
                await model.update($0, stage: .output)
                return model.output
            }
            Section {
                Text("Start audio and enable Live Monitoring in Session to hear your instrument.")
                    .foregroundStyle(.secondary)
            }
            if let error = model.errorMessage {
                Section { Text(error).foregroundStyle(.red) }
            }
        }
        .navigationTitle("Tone")
        .task { await model.refresh() }
    }

}

private struct GainSection: View {
    let title: String
    let configuration: GainConfiguration
    let isBusy: Bool
    let update: (GainConfiguration) async -> GainConfiguration
    @State private var draftDecibels: Double

    init(title: String, configuration: GainConfiguration, isBusy: Bool, update: @escaping (GainConfiguration) async -> GainConfiguration) {
        self.title = title
        self.configuration = configuration
        self.isBusy = isBusy
        self.update = update
        _draftDecibels = State(initialValue: Double(configuration.decibels))
    }

    var body: some View {
        Section(title) {
            LabeledContent("Gain", value: String(format: "%.1f dB", draftDecibels))
            Slider(value: $draftDecibels, in: -24...24, step: 0.5) { editing in
                if !editing {
                    Task {
                        let committed = await update(GainConfiguration(decibels: Float(draftDecibels), bypassed: configuration.bypassed))
                        draftDecibels = Double(committed.decibels)
                    }
                }
            }
            .accessibilityLabel(title)
            Toggle("Bypass", isOn: Binding(
                get: { configuration.bypassed },
                set: { value in
                    Task { _ = await update(GainConfiguration(decibels: configuration.decibels, bypassed: value)) }
                }
            ))
        }
        .disabled(isBusy)
        .onChange(of: configuration.decibels) { _, value in draftDecibels = Double(value) }
    }
}
