import AVFoundation
import Foundation

protocol AudioSessionManaging: AnyObject, Sendable {
    var snapshot: AudioSessionSnapshot { get async }

    func activate() async throws(AudioSessionError) -> AudioSessionSnapshot
    func deactivate() async throws(AudioSessionError)
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

    private(set) var snapshot: AudioSessionSnapshot

    init(
        backend: any AudioSessionBackend,
        configuration: AudioSessionConfiguration = .bassPractice
    ) {
        self.backend = backend
        self.configuration = configuration
        snapshot = AudioSessionSnapshot(
            requestedSampleRate: configuration.preferredSampleRate,
            requestedIOBufferDuration: configuration.preferredIOBufferDuration,
            actualSampleRate: nil,
            actualIOBufferDuration: nil,
            isActive: false
        )
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
}

protocol AudioSessionBackend: Sendable {
    var sampleRate: Double { get }
    var ioBufferDuration: TimeInterval { get }

    func configureForMeasurement() throws
    func setPreferredSampleRate(_ sampleRate: Double) throws
    func setPreferredIOBufferDuration(_ duration: TimeInterval) throws
    func setActive(_ active: Bool, notifyOthersOnDeactivation: Bool) throws
}

final class SystemAudioSessionBackend: AudioSessionBackend, @unchecked Sendable {
    private let session: AVAudioSession

    var sampleRate: Double {
        session.sampleRate
    }

    var ioBufferDuration: TimeInterval {
        session.ioBufferDuration
    }

    init(session: AVAudioSession = .sharedInstance()) {
        self.session = session
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
