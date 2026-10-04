import AVFoundation

protocol AudioEngineProtocol: AnyObject, Sendable {
    var state: AudioEngineState { get async }
    var monitoringEnabled: Bool { get async }
    var monitoringGain: Float { get async }

    func start() async throws(AudioEngineFailure)
    func stop() async throws(AudioEngineFailure)
    func setMonitoring(enabled: Bool, gain: Float) async throws(AudioEngineFailure)
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
    case invalidInputFormat(sampleRate: Double, channelCount: UInt32)
    case graphConfigurationFailed
    case preparationFailed
    case startFailed
    case monitoringConfigurationFailed
    case sessionDeactivation(AudioSessionError)
}

protocol AudioEngineBackend: Sendable {
    var inputFormat: AudioEngineInputFormat { get }

    func resetGraph() throws
    func attachInstrumentMixer() throws
    func connectInputToInstrument(format: AudioEngineInputFormat) throws
    func connectInstrumentToMain() throws
    func connectMainToOutput() throws
    func setInstrumentMixerVolume(_ volume: Float) throws
    func prepare() throws
    func start() throws
    func stop()
}

struct AudioEngineInputFormat: Equatable, Sendable {
    let sampleRate: Double
    let channelCount: UInt32

    init(audioFormat: AVAudioFormat) {
        sampleRate = audioFormat.sampleRate
        channelCount = audioFormat.channelCount
    }

    init(sampleRate: Double, channelCount: UInt32) {
        self.sampleRate = sampleRate
        self.channelCount = channelCount
    }
}

final class SystemAudioEngineBackend: AudioEngineBackend, @unchecked Sendable {
    private enum BackendError: Error {
        case missingAudioFormat
    }

    private let engine: AVAudioEngine
    private let instrumentMixer: AVAudioMixerNode

    var inputFormat: AudioEngineInputFormat {
        AudioEngineInputFormat(audioFormat: engine.inputNode.outputFormat(forBus: 0))
    }

    init(
        engine: AVAudioEngine = AVAudioEngine(),
        instrumentMixer: AVAudioMixerNode = AVAudioMixerNode()
    ) {
        self.engine = engine
        self.instrumentMixer = instrumentMixer
    }

    func resetGraph() throws {
        engine.stop()
        engine.disconnectNodeOutput(engine.inputNode)
        if instrumentMixer.engine != nil {
            engine.disconnectNodeInput(instrumentMixer)
            engine.disconnectNodeOutput(instrumentMixer)
            engine.detach(instrumentMixer)
        }
        engine.disconnectNodeInput(engine.mainMixerNode)
        engine.disconnectNodeOutput(engine.mainMixerNode)
        engine.disconnectNodeInput(engine.outputNode)
        engine.reset()
    }

    func attachInstrumentMixer() throws {
        engine.attach(instrumentMixer)
    }

    func connectInputToInstrument(format: AudioEngineInputFormat) throws {
        let audioFormat = engine.inputNode.outputFormat(forBus: 0)
        guard audioFormat.sampleRate == format.sampleRate,
              audioFormat.channelCount == format.channelCount else {
            throw BackendError.missingAudioFormat
        }
        engine.connect(
            engine.inputNode,
            to: instrumentMixer,
            format: audioFormat
        )
    }

    func connectInstrumentToMain() throws {
        engine.connect(instrumentMixer, to: engine.mainMixerNode, format: nil)
    }

    func connectMainToOutput() throws {
        engine.connect(engine.mainMixerNode, to: engine.outputNode, format: nil)
    }

    func setInstrumentMixerVolume(_ volume: Float) throws {
        instrumentMixer.outputVolume = volume
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
