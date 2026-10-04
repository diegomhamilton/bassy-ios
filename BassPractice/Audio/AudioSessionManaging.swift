import AVFoundation
import Foundation
import UIKit

protocol AudioSessionManaging: AnyObject, Sendable {
    var snapshot: AudioSessionSnapshot { get async }
    var currentRoute: AudioRoute { get async }
    var availableInputs: [AudioInput] { get async }
    var preferredInput: AudioInput? { get async }

    func activate() async throws(AudioSessionError) -> AudioSessionSnapshot
    func deactivate() async throws(AudioSessionError)
    func selectPreferredInput(id: String?) async throws(AudioSessionError)
    func events() async -> AsyncStream<AudioSessionEvent>
}

struct AudioSessionConfiguration: Equatable, Sendable {
    let preferredSampleRate: Double
    let preferredIOBufferDuration: TimeInterval

    static let bassPractice = AudioSessionConfiguration(
        preferredSampleRate: 48_000,
        preferredIOBufferDuration: 0.00533
    )
}

struct AudioSessionSnapshot: Equatable, Sendable {
    let requestedSampleRate: Double
    let requestedIOBufferDuration: TimeInterval
    let actualSampleRate: Double?
    let actualIOBufferDuration: TimeInterval?
    let isActive: Bool
}

enum AudioSessionError: Error, Equatable, Sendable {
    case categoryConfigurationFailed
    case preferredSampleRateFailed(requested: Double)
    case preferredIOBufferDurationFailed(requested: TimeInterval)
    case activationFailed
    case deactivationFailed
    case inputUnavailable(id: String)
    case inputSelectionFailed(id: String?)
}

actor AudioControlActor: AudioSessionManaging, AudioEngineProtocol {
    private let backend: any AudioSessionBackend
    private let engineBackend: any AudioEngineBackend
    private let configuration: AudioSessionConfiguration
    private var eventContinuations: [UUID: AsyncStream<AudioSessionEvent>.Continuation] = [:]
    private var observationTask: Task<Void, Never>?
    private var wasActiveBeforeInterruption = false
    private var isInBackground = false

    private(set) var snapshot: AudioSessionSnapshot
    private(set) var currentRoute: AudioRoute
    private(set) var availableInputs: [AudioInput]
    private(set) var preferredInput: AudioInput?
    private(set) var state: AudioEngineState = .stopped

    init(
        backend: any AudioSessionBackend,
        engineBackend: any AudioEngineBackend = SystemAudioEngineBackend(),
        configuration: AudioSessionConfiguration = .bassPractice
    ) {
        self.backend = backend
        self.engineBackend = engineBackend
        self.configuration = configuration
        currentRoute = backend.currentRoute
        availableInputs = backend.availableInputs
        preferredInput = nil
        snapshot = AudioSessionSnapshot(
            requestedSampleRate: configuration.preferredSampleRate,
            requestedIOBufferDuration: configuration.preferredIOBufferDuration,
            actualSampleRate: nil,
            actualIOBufferDuration: nil,
            isActive: false
        )

    }

    func start() throws(AudioEngineFailure) {
        guard state != .running, state != .starting else {
            return
        }

        state = .starting

        do {
            _ = try activate()
        } catch {
            let failure = AudioEngineFailure.sessionActivation(error)
            deactivateAfterFailedStart()
            state = .failed(failure)
            throw failure
        }

        do {
            try configureGraph()
        } catch let failure {
            engineBackend.stop()
            deactivateAfterFailedStart()
            state = .failed(failure)
            throw failure
        }

        do {
            try engineBackend.prepare()
        } catch {
            let failure = AudioEngineFailure.preparationFailed
            engineBackend.stop()
            deactivateAfterFailedStart()
            state = .failed(failure)
            throw failure
        }

        do {
            try engineBackend.start()
        } catch {
            let failure = AudioEngineFailure.startFailed
            engineBackend.stop()
            deactivateAfterFailedStart()
            state = .failed(failure)
            throw failure
        }

        state = .running
    }

    private func configureGraph() throws(AudioEngineFailure) {
        let inputFormat = engineBackend.inputFormat
        guard inputFormat.sampleRate > 0, inputFormat.channelCount > 0 else {
            throw .invalidInputFormat(
                sampleRate: inputFormat.sampleRate,
                channelCount: inputFormat.channelCount
            )
        }

        do {
            try engineBackend.resetGraph()
            try engineBackend.attachInstrumentMixer()
            try engineBackend.connectInputToInstrument(format: inputFormat)
            try engineBackend.connectInstrumentToMain()
            try engineBackend.connectMainToOutput()
        } catch {
            throw .graphConfigurationFailed
        }
    }

    func stop() throws(AudioEngineFailure) {
        guard state != .stopped else {
            return
        }

        engineBackend.stop()

        do {
            try deactivate()
        } catch {
            let failure = AudioEngineFailure.sessionDeactivation(error)
            state = .failed(failure)
            throw failure
        }

        state = .stopped
    }

    private func deactivateAfterFailedStart() {
        if snapshot.isActive {
            try? deactivate()
        } else {
            try? backend.setActive(false, notifyOthersOnDeactivation: true)
        }
    }

    func events() -> AsyncStream<AudioSessionEvent> {
        startObservationIfNeeded()
        let identifier = UUID()
        let (stream, continuation) = AsyncStream<AudioSessionEvent>.makeStream()
        eventContinuations[identifier] = continuation
        continuation.onTermination = { [weak self] _ in
            Task {
                await self?.removeEventContinuation(identifier: identifier)
            }
        }
        return stream
    }

    func activate() throws(AudioSessionError) -> AudioSessionSnapshot {
        guard !snapshot.isActive else {
            return snapshot
        }

        do {
            try backend.configureForMeasurement()
        } catch {
            throw .categoryConfigurationFailed
        }

        do {
            try backend.setPreferredSampleRate(configuration.preferredSampleRate)
        } catch {
            throw .preferredSampleRateFailed(requested: configuration.preferredSampleRate)
        }

        do {
            try backend.setPreferredIOBufferDuration(configuration.preferredIOBufferDuration)
        } catch {
            throw .preferredIOBufferDurationFailed(
                requested: configuration.preferredIOBufferDuration
            )
        }

        do {
            try backend.setActive(true, notifyOthersOnDeactivation: false)
        } catch {
            throw .activationFailed
        }

        snapshot = AudioSessionSnapshot(
            requestedSampleRate: configuration.preferredSampleRate,
            requestedIOBufferDuration: configuration.preferredIOBufferDuration,
            actualSampleRate: backend.sampleRate,
            actualIOBufferDuration: backend.ioBufferDuration,
            isActive: true
        )
        availableInputs = backend.availableInputs
        return snapshot
    }

    func deactivate() throws(AudioSessionError) {
        guard snapshot.isActive else {
            return
        }

        do {
            try backend.setActive(false, notifyOthersOnDeactivation: true)
        } catch {
            throw .deactivationFailed
        }

        snapshot = AudioSessionSnapshot(
            requestedSampleRate: snapshot.requestedSampleRate,
            requestedIOBufferDuration: snapshot.requestedIOBufferDuration,
            actualSampleRate: snapshot.actualSampleRate,
            actualIOBufferDuration: snapshot.actualIOBufferDuration,
            isActive: false
        )
    }

    func selectPreferredInput(id: String?) throws(AudioSessionError) {
        let refreshedInputs = backend.availableInputs
        availableInputs = refreshedInputs

        guard let id else {
            do {
                try backend.setPreferredInput(id: nil)
            } catch {
                throw .inputSelectionFailed(id: nil)
            }
            preferredInput = nil
            return
        }

        guard let input = refreshedInputs.first(where: { $0.id == id }) else {
            throw .inputUnavailable(id: id)
        }

        do {
            try backend.setPreferredInput(id: id)
        } catch {
            throw .inputSelectionFailed(id: id)
        }
        preferredInput = input
    }

    private func receive(
        _ event: AudioSessionBackendEvent,
        from backend: any AudioSessionBackend
    ) {
        switch event {
        case let .routeChanged(reason):
            currentRoute = backend.currentRoute
            availableInputs = backend.availableInputs
            reconcilePreferredInput(using: backend)
            let routedEvent = AudioSessionEvent.routeChanged(
                route: currentRoute,
                reason: reason
            )
            publish(routedEvent)
        case .interruptionBegan:
            wasActiveBeforeInterruption = snapshot.isActive
            snapshot = snapshot.withActiveState(false)
            publish(.interruptionBegan)
        case let .interruptionEnded(shouldResume):
            let shouldReactivate = shouldResume && wasActiveBeforeInterruption && !isInBackground
            wasActiveBeforeInterruption = false
            if shouldReactivate {
                _ = try? activate()
            }
            publish(.interruptionEnded(shouldResume: shouldResume))
        case .enteredBackground:
            isInBackground = true
            try? deactivate()
            publish(.enteredBackground)
        case .enteredForeground:
            isInBackground = false
            currentRoute = backend.currentRoute
            availableInputs = backend.availableInputs
            reconcilePreferredInput(using: backend)
            publish(.enteredForeground)
        }
    }

    private func reconcilePreferredInput(using backend: any AudioSessionBackend) {
        guard let preferredInput else {
            return
        }

        if let refreshedInput = availableInputs.first(where: { $0.id == preferredInput.id }) {
            self.preferredInput = refreshedInput
        } else {
            try? backend.setPreferredInput(id: nil)
            self.preferredInput = nil
        }
    }

    private func publish(_ event: AudioSessionEvent) {
        for continuation in eventContinuations.values {
            continuation.yield(event)
        }
    }

    private func removeEventContinuation(identifier: UUID) {
        eventContinuations[identifier] = nil
        guard eventContinuations.isEmpty else {
            return
        }
        observationTask?.cancel()
        observationTask = nil
    }

    private func startObservationIfNeeded() {
        guard observationTask == nil else {
            return
        }
        let backend = backend
        observationTask = Task { [weak self] in
            for await event in backend.events {
                guard !Task.isCancelled else {
                    return
                }
                await self?.receive(event, from: backend)
            }
        }
    }
}

enum AudioSessionBackendEvent: Equatable, Sendable {
    case routeChanged(reason: AudioRouteChangeReason)
    case interruptionBegan
    case interruptionEnded(shouldResume: Bool)
    case enteredBackground
    case enteredForeground
}

protocol AudioSessionBackend: Sendable {
    var sampleRate: Double { get }
    var ioBufferDuration: TimeInterval { get }
    var currentRoute: AudioRoute { get }
    var availableInputs: [AudioInput] { get }
    var events: AsyncStream<AudioSessionBackendEvent> { get }

    func configureForMeasurement() throws
    func setPreferredSampleRate(_ sampleRate: Double) throws
    func setPreferredIOBufferDuration(_ duration: TimeInterval) throws
    func setActive(_ active: Bool, notifyOthersOnDeactivation: Bool) throws
    func setPreferredInput(id: String?) throws
}

final class SystemAudioSessionBackend: AudioSessionBackend, @unchecked Sendable {
    private let session: AVAudioSession
    private let notificationCenter: NotificationCenter
    private let eventContinuation: AsyncStream<AudioSessionBackendEvent>.Continuation
    private var notificationObservers: [NSObjectProtocol] = []

    let events: AsyncStream<AudioSessionBackendEvent>

    var sampleRate: Double {
        session.sampleRate
    }

    var ioBufferDuration: TimeInterval {
        session.ioBufferDuration
    }

    var currentRoute: AudioRoute {
        AudioRoute(
            inputs: session.currentRoute.inputs.map(AudioDevice.init(portDescription:)),
            outputs: session.currentRoute.outputs.map(AudioDevice.init(portDescription:))
        )
    }

    var availableInputs: [AudioInput] {
        (session.availableInputs ?? []).map(AudioInput.init(portDescription:))
    }

    init(
        session: AVAudioSession = .sharedInstance(),
        notificationCenter: NotificationCenter = .default
    ) {
        self.session = session
        self.notificationCenter = notificationCenter
        let (events, continuation) = AsyncStream<AudioSessionBackendEvent>.makeStream()
        self.events = events
        eventContinuation = continuation
        notificationObservers.append(notificationCenter.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: session,
            queue: nil
        ) { notification in
            let rawReason = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt
            continuation.yield(
                .routeChanged(reason: AudioRouteChangeReason(rawValue: rawReason))
            )
        })
        notificationObservers.append(notificationCenter.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: session,
            queue: nil
        ) { notification in
            guard let rawType = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: rawType) else {
                return
            }
            switch type {
            case .began:
                continuation.yield(.interruptionBegan)
            case .ended:
                let rawOptions = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
                let options = AVAudioSession.InterruptionOptions(rawValue: rawOptions)
                continuation.yield(
                    .interruptionEnded(shouldResume: options.contains(.shouldResume))
                )
            @unknown default:
                return
            }
        })
        notificationObservers.append(notificationCenter.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: nil
        ) { _ in
            continuation.yield(.enteredBackground)
        })
        notificationObservers.append(notificationCenter.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: nil
        ) { _ in
            continuation.yield(.enteredForeground)
        })
    }

    deinit {
        for observer in notificationObservers {
            notificationCenter.removeObserver(observer)
        }
        eventContinuation.finish()
    }

    func configureForMeasurement() throws {
        try session.setCategory(.playAndRecord, mode: .measurement, options: [])
    }

    func setPreferredSampleRate(_ sampleRate: Double) throws {
        try session.setPreferredSampleRate(sampleRate)
    }

    func setPreferredIOBufferDuration(_ duration: TimeInterval) throws {
        try session.setPreferredIOBufferDuration(duration)
    }

    func setActive(_ active: Bool, notifyOthersOnDeactivation: Bool) throws {
        let options: AVAudioSession.SetActiveOptions = notifyOthersOnDeactivation
            ? [.notifyOthersOnDeactivation]
            : []
        try session.setActive(active, options: options)
    }

    func setPreferredInput(id: String?) throws {
        let port: AVAudioSessionPortDescription?
        if let id {
            guard let availablePort = session.availableInputs?.first(where: { $0.uid == id }) else {
                throw SystemAudioSessionBackendError.inputUnavailable
            }
            port = availablePort
        } else {
            port = nil
        }
        try session.setPreferredInput(port)
    }
}

private enum SystemAudioSessionBackendError: Error {
    case inputUnavailable
}

private extension AudioSessionSnapshot {
    func withActiveState(_ isActive: Bool) -> Self {
        AudioSessionSnapshot(
            requestedSampleRate: requestedSampleRate,
            requestedIOBufferDuration: requestedIOBufferDuration,
            actualSampleRate: actualSampleRate,
            actualIOBufferDuration: actualIOBufferDuration,
            isActive: isActive
        )
    }
}

private extension AudioDevice {
    init(portDescription: AVAudioSessionPortDescription) {
        self.init(
            id: portDescription.uid,
            name: portDescription.portName,
            portType: portDescription.portType.rawValue
        )
    }
}

private extension AudioInput {
    init(portDescription: AVAudioSessionPortDescription) {
        self.init(
            id: portDescription.uid,
            name: portDescription.portName,
            portType: portDescription.portType.rawValue
        )
    }
}

private extension AudioRouteChangeReason {
    init(rawValue: UInt?) {
        guard let rawValue else {
            self = .unknown
            return
        }

        switch AVAudioSession.RouteChangeReason(rawValue: rawValue) {
        case .unknown:
            self = .unknown
        case .newDeviceAvailable:
            self = .newDeviceAvailable
        case .oldDeviceUnavailable:
            self = .oldDeviceUnavailable
        case .categoryChange:
            self = .categoryChange
        case .override:
            self = .override
        case .wakeFromSleep:
            self = .wakeFromSleep
        case .noSuitableRouteForCategory:
            self = .noSuitableRouteForCategory
        case .routeConfigurationChange:
            self = .routeConfigurationChange
        case .none:
            self = .unrecognized(rawValue)
        @unknown default:
            self = .unrecognized(rawValue)
        }
    }
}
