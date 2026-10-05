import Foundation
import Observation

@MainActor @Observable
final class SessionModel {
    private let engine: any AudioEngineProtocol
    private let session: any AudioSessionManaging
    private let permission: any AudioRecordingPermission
    private(set) var state: AudioEngineState = .stopped
    private(set) var inputs: [AudioInput] = []
    private(set) var selectedInputID: String?
    private(set) var route: AudioRoute = .empty
    private(set) var diagnostics: AudioEngineDiagnostics?
    private(set) var monitoringEnabled = false
    private(set) var monitoringGain: Float = 1
    private(set) var isBusy = false
    private(set) var errorMessage: String?

    init(engine: any AudioEngineProtocol, session: any AudioSessionManaging, permission: any AudioRecordingPermission = SystemAudioRecordingPermission()) {
        self.engine = engine
        self.session = session
        self.permission = permission
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
