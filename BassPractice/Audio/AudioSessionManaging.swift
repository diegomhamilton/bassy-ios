import AVFoundation
import Foundation

protocol AudioSessionManaging: AnyObject, Sendable {
    var snapshot: AudioSessionSnapshot { get async }
    var currentRoute: AudioRoute { get async }

    func activate() async throws(AudioSessionError) -> AudioSessionSnapshot
    func deactivate() async throws(AudioSessionError)
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
}

actor AudioControlActor: AudioSessionManaging {
    private let backend: any AudioSessionBackend
    private let configuration: AudioSessionConfiguration
    private var eventContinuations: [UUID: AsyncStream<AudioSessionEvent>.Continuation] = [:]
    private var observationTask: Task<Void, Never>?

    private(set) var snapshot: AudioSessionSnapshot
    private(set) var currentRoute: AudioRoute

    init(
        backend: any AudioSessionBackend,
        configuration: AudioSessionConfiguration = .bassPractice
    ) {
        self.backend = backend
        self.configuration = configuration
        currentRoute = backend.currentRoute
        snapshot = AudioSessionSnapshot(
            requestedSampleRate: configuration.preferredSampleRate,
            requestedIOBufferDuration: configuration.preferredIOBufferDuration,
            actualSampleRate: nil,
            actualIOBufferDuration: nil,
            isActive: false
        )

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

    private func receive(
        _ event: AudioSessionBackendEvent,
        from backend: any AudioSessionBackend
    ) {
        switch event {
        case let .routeChanged(reason):
            currentRoute = backend.currentRoute
            let routedEvent = AudioSessionEvent.routeChanged(
                route: currentRoute,
                reason: reason
            )
            for continuation in eventContinuations.values {
                continuation.yield(routedEvent)
            }
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
}

protocol AudioSessionBackend: Sendable {
    var sampleRate: Double { get }
    var ioBufferDuration: TimeInterval { get }
    var currentRoute: AudioRoute { get }
    var events: AsyncStream<AudioSessionBackendEvent> { get }

    func configureForMeasurement() throws
    func setPreferredSampleRate(_ sampleRate: Double) throws
    func setPreferredIOBufferDuration(_ duration: TimeInterval) throws
    func setActive(_ active: Bool, notifyOthersOnDeactivation: Bool) throws
}

final class SystemAudioSessionBackend: AudioSessionBackend, @unchecked Sendable {
    private let session: AVAudioSession
    private let notificationCenter: NotificationCenter
    private let eventContinuation: AsyncStream<AudioSessionBackendEvent>.Continuation
    private var routeChangeObserver: NSObjectProtocol?

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

    init(
        session: AVAudioSession = .sharedInstance(),
        notificationCenter: NotificationCenter = .default
    ) {
        self.session = session
        self.notificationCenter = notificationCenter
        let (events, continuation) = AsyncStream<AudioSessionBackendEvent>.makeStream()
        self.events = events
        eventContinuation = continuation
        routeChangeObserver = notificationCenter.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: session,
            queue: nil
        ) { notification in
            let rawReason = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt
            continuation.yield(
                .routeChanged(reason: AudioRouteChangeReason(rawValue: rawReason))
            )
        }
    }

    deinit {
        if let routeChangeObserver {
            notificationCenter.removeObserver(routeChangeObserver)
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
