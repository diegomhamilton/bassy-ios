import SwiftUI

struct SessionView: View {
    @State private var model: SessionModel
    @State private var gain: Float = 1
    @State private var profiles: ProfileSelectionModel
    @State private var playbackVolume: Float = 1

    init(audioEngine: any AudioEngineProtocol, audioSession: any AudioSessionManaging, toneController: any AudioToneControlling, profileRepository: any InputProfileRepository, files: any AudioFileStore) {
        _model = State(initialValue: SessionModel(engine: audioEngine, session: audioSession, files: files))
        _profiles = State(initialValue: ProfileSelectionModel(controller: toneController, repository: profileRepository))
    }

    var body: some View {
        Form {
            Section("Audio") {
                LabeledContent("State", value: stateLabel)
                Button(model.state == .running ? "Stop Audio" : "Start Audio") {
                    Task { await model.toggleRunning() }
                }.disabled(model.isBusy)
                if model.state == .interrupted {
                    Button("Stop Audio") { Task { await model.stop() } }.disabled(model.isBusy)
                }
                Picker("Input", selection: Binding(
                    get: { model.selectedInputID },
                    set: { id in Task { await model.selectInput(id) } }
                )) {
                    Text("System Default").tag(String?.none)
                    ForEach(model.inputs) { Text($0.name).tag(Optional($0.id)) }
                }.disabled(model.isBusy || model.state == .running)
                Text("Start and stop audio to discover inputs, then choose an input before starting again.").font(.caption).foregroundStyle(.secondary)
            }
            Section("Instrument Profile") { ProfilePicker(model: profiles) }
            Section("Recording") {
                if case let .recording(_, _, startedAt) = model.recordingState {
                    Text("Recording since \(startedAt, style: .time)").foregroundStyle(.red)
                    Button("Stop Recording") { Task { await model.toggleRecording() } }
                } else {
                    Button("Record Processed Instrument") { Task { await model.toggleRecording() } }
                        .disabled(model.state != .running)
                    Text("Start audio first. Live Monitoring can stay off while recording.").font(.caption).foregroundStyle(.secondary)
                }
                if case let .failed(failure) = model.recordingState { Text(failure.message).foregroundStyle(.red) }
                ForEach(model.recordings) { recording in
                    HStack {
                        Text(recording.createdAt, style: .time)
                        Spacer()
                        Text(String(format: "%.1f s", recording.duration)).foregroundStyle(.secondary)
                        Button("Play") { Task { await model.playRecording(recording) } }
                    }
                }
                if case .playing = model.playbackState { Button("Stop Playback") { Task { await model.stopPlayback() } } }
            }.disabled(model.isBusy)
            Section("Playback Mix") {
                Toggle("Mute Playback", isOn: Binding(
                    get: { model.playbackMix.muted },
                    set: { value in Task { await model.updatePlaybackMix(MixerChannelConfiguration(volume: model.playbackMix.volume, muted: value)) } }
                ))
                LabeledContent("Volume", value: "\(Int(playbackVolume * 100))%")
                Slider(value: $playbackVolume, in: 0...1) { editing in
                    if !editing { Task { await model.updatePlaybackMix(MixerChannelConfiguration(volume: playbackVolume, muted: model.playbackMix.muted)); playbackVolume = model.playbackMix.volume } }
                }
            }.disabled(model.isBusy)
            Section("Source Levels") {
                TimelineView(.periodic(from: .now, by: 0.2)) { context in
                    VStack(alignment: .leading) {
                        levelRow("Instrument", level: model.instrumentLevel)
                        levelRow("Playback", level: model.playbackLevel)
                    }.task(id: context.date) { await model.refreshLevels() }
                }
                Text("Levels are measured before each source volume/mute. A muted source can still show signal.").font(.caption).foregroundStyle(.secondary)
            }
            Section("Monitoring") {
                Toggle("Live Monitoring", isOn: Binding(
                    get: { model.monitoringEnabled },
                    set: { enabled in Task { await model.setMonitoring(enabled: enabled, gain: model.monitoringGain) } }
                ))
                LabeledContent("Gain", value: "\(Int(gain * 100))%")
                Slider(value: $gain, in: 0...1) { editing in
                    if !editing {
                        Task {
                            await model.setMonitoring(enabled: model.monitoringEnabled, gain: gain)
                            gain = model.monitoringGain
                        }
                    }
                }
                Text("Use headphones to avoid microphone feedback.").font(.caption).foregroundStyle(.secondary)
            }.disabled(model.isBusy)
            Section("Current Route") {
                LabeledContent("Input", value: names(model.route.inputs))
                LabeledContent("Output", value: names(model.route.outputs))
            }
            Section("Actual Audio Diagnostics") {
                if let value = model.diagnostics {
                    LabeledContent("Session Sample Rate", value: String(format: "%.0f Hz", value.actualSessionSampleRate))
                    LabeledContent("Input Channels", value: String(value.inputChannelCount))
                    LabeledContent("Input Format", value: format(value.inputFormat))
                    LabeledContent("Output Format", value: format(value.outputFormat))
                    LabeledContent("IO Buffer", value: String(format: "%.2f ms", value.actualIOBufferDuration * 1000))
                } else { Text("Start audio to read the actual hardware formats.") }
                Button("Refresh Diagnostics") { Task { await model.refresh() } }.disabled(model.isBusy)
            }
            if let error = model.errorMessage {
                Section("Audio Error") { Text(error).foregroundStyle(.red) }
            }
        }
        .navigationTitle("Session")
        .task { await model.observe() }
        .task { await profiles.refresh() }
        .onChange(of: model.monitoringGain) { _, value in gain = value }
        .onChange(of: model.playbackMix.volume) { _, value in playbackVolume = value }
    }

    private var stateLabel: String {
        switch model.state {
        case .stopped: "Stopped"
        case .starting: "Starting"
        case .running: "Running"
        case .interrupted: "Interrupted"
        case .failed: "Failed"
        }
    }

    private func levelRow(_ title: String, level: AudioLevel?) -> some View {
        VStack(alignment: .leading) {
            HStack {
                Text(title)
                Spacer()
                Text(level.map { $0.clipping ? "Clipping" : ($0.peak > 0.0001 ? "Signal" : "No Signal") } ?? "Unavailable")
                    .foregroundStyle(level?.clipping == true ? .red : .secondary)
            }
            ProgressView(value: Double(min(level?.peak ?? 0, 1)))
        }
    }

    private func names(_ devices: [AudioDevice]) -> String {
        devices.isEmpty ? "None" : devices.map(\.name).joined(separator: ", ")
    }

    private func format(_ value: AudioFormatDiagnostics) -> String {
        "\(Int(value.sampleRate)) Hz · \(value.channelCount) ch · \(value.sampleEncoding) · \(value.isInterleaved ? "interleaved" : "noninterleaved")"
    }
}
