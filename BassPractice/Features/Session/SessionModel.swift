import Foundation
import Observation

@MainActor @Observable
final class SessionModel {
    private let engine: any AudioEngineProtocol
    private let session: any AudioSessionManaging
    private let permission: any AudioRecordingPermission
    private let files: (any AudioFileStore)?
    private let recordingController: (any AudioRecordingControlling)?
    private let playbackController: (any AudioPlaybackControlling)?
    private let mixer: (any AudioMixerControlling)?
    private let practiceSessionID = UUID()
    private(set) var state: AudioEngineState = .stopped
    private(set) var inputs: [AudioInput] = []
    private(set) var selectedInputID: String?
    private(set) var route: AudioRoute = .empty
    private(set) var diagnostics: AudioEngineDiagnostics?
    private(set) var monitoringEnabled = false
    private(set) var monitoringGain: Float = 1
    private(set) var isBusy = false
    private(set) var errorMessage: String?
    private(set) var recordingState: AudioRecordingState = .idle
    private(set) var recordings: [Recording] = []
    private(set) var playbackState: AudioPlaybackState = .stopped
    private(set) var playbackMix = MixerChannelConfiguration(volume: 1, muted: false)
    private(set) var instrumentLevel: AudioLevel?
    private(set) var playbackLevel: AudioLevel?

    init(engine: any AudioEngineProtocol, session: any AudioSessionManaging, permission: any AudioRecordingPermission = SystemAudioRecordingPermission(), files: (any AudioFileStore)? = nil) {
        self.engine = engine
        self.session = session
        self.permission = permission
        self.files = files
        recordingController = engine as? any AudioRecordingControlling
        playbackController = engine as? any AudioPlaybackControlling
        mixer = engine as? any AudioMixerControlling
    }

    func observe() async {
        let events = await session.events()
        await refresh()
        for await _ in events {
            guard !Task.isCancelled else { return }
            await refresh()
        }
    }

    func refresh() async {
        state = await engine.state
        inputs = await session.availableInputs
        selectedInputID = await session.preferredInput?.id
        route = await session.currentRoute
        diagnostics = await engine.diagnostics
        monitoringEnabled = await engine.monitoringEnabled
        monitoringGain = await engine.monitoringGain
        recordingState = await recordingController?.recordingState ?? .idle
        recordings = await recordingController?.recordings ?? []
        playbackState = await playbackController?.playbackState ?? .stopped
        playbackMix = await mixer?.mixerConfiguration(for: .playback) ?? MixerChannelConfiguration(volume: 1, muted: false)
    }

    func toggleRecording() async {
        guard !isBusy else { return }
        isBusy = true
        defer { isBusy = false }
        errorMessage = nil
        guard let recordingController, let files else { errorMessage = "Recording storage is unavailable."; return }
        do {
            if case .recording = await recordingController.recordingState { _ = try await recordingController.stopRecording() }
            else {
                let id = UUID()
                let fileURL = try files.recordingURL(sessionID: practiceSessionID, recordingID: id)
                try await recordingController.startRecording(id: id, to: fileURL)
            }
        } catch { errorMessage = (error as? AudioRecordingFailure)?.message ?? "Recording storage is unavailable. Check available storage and try again." }
        await refresh()
    }

    func playRecording(_ recording: Recording) async {
        guard !isBusy else { return }
        isBusy = true
        defer { isBusy = false }
        errorMessage = nil
        guard let playbackController else { errorMessage = "Playback is unavailable."; return }
        do {
            if await engine.state != .running {
                guard await permission.request() else { errorMessage = "Enable microphone access in Settings to start the audio engine."; return }
                try await engine.start()
            }
            try await playbackController.play(recording)
        } catch { errorMessage = (error as? AudioPlaybackFailure)?.message ?? "The audio engine could not start. Try again." }
        await refresh()
    }

    func stopPlayback() async {
        await playbackController?.stopPlayback()
        await refresh()
    }

    func updatePlaybackMix(_ configuration: MixerChannelConfiguration) async {
        guard !isBusy, let mixer else { return }
        isBusy = true
        defer { isBusy = false }
        errorMessage = nil
        do { try await mixer.setMixerConfiguration(configuration, for: .playback) }
        catch { errorMessage = "Could not change playback volume. The previous setting was retained." }
        await refresh()
    }

    func refreshLevels() async {
        instrumentLevel = await mixer?.level(for: .instrument)
        playbackLevel = await mixer?.level(for: .playback)
    }

    func toggleRunning() async {
        guard !isBusy else { return }
        isBusy = true
        defer { isBusy = false }
        errorMessage = nil
        do {
            if state == .running { try await engine.stop() }
            else {
                guard await permission.request() else {
                    errorMessage = "Microphone access is required. Enable it in Settings to start audio."
                    return
                }
                try await engine.start()
            }
        } catch { errorMessage = String(describing: error) }
        await refresh()
    }

    func stop() async {
        guard !isBusy else { return }
        isBusy = true
        defer { isBusy = false }
        errorMessage = nil
        do { try await engine.stop() }
        catch { errorMessage = String(describing: error) }
        await refresh()
    }

    func selectInput(_ id: String?) async {
        guard !isBusy, state != .running else { return }
        isBusy = true
        defer { isBusy = false }
        errorMessage = nil
        do { try await session.selectPreferredInput(id: id) }
        catch { errorMessage = String(describing: error) }
        await refresh()
    }

    func setMonitoring(enabled: Bool, gain: Float) async {
        guard !isBusy else { return }
        isBusy = true
        defer { isBusy = false }
        errorMessage = nil
        do { try await engine.setMonitoring(enabled: enabled, gain: gain) }
        catch { errorMessage = String(describing: error) }
        await refresh()
    }
}
