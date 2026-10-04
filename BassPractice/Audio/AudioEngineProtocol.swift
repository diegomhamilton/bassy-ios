import AVFoundation

protocol AudioEngineProtocol: AnyObject, Sendable {
    var state: AudioEngineState { get async }

    func start() async throws(AudioEngineFailure)
    func stop() async throws(AudioEngineFailure)
}

enum AudioEngineState: Equatable, Sendable {
    case stopped
    case starting
    case running
    case interrupted
    case failed(AudioEngineFailure)
}

enum AudioEngineFailure: Error, Equatable, Sendable {
    case sessionActivation(AudioSessionError)
    case preparationFailed
    case startFailed
    case sessionDeactivation(AudioSessionError)
}

protocol AudioEngineBackend: Sendable {
    func prepare() throws
    func start() throws
    func stop()
}

final class SystemAudioEngineBackend: AudioEngineBackend, @unchecked Sendable {
    private let engine: AVAudioEngine

    init(engine: AVAudioEngine = AVAudioEngine()) {
        self.engine = engine
    }

    func prepare() throws {
        engine.prepare()
    }

    func start() throws {
        try engine.start()
    }

    func stop() {
        engine.stop()
    }
}
