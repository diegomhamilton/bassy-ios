import Foundation
import Testing
@testable import BassPractice

@Suite("Audio engine lifecycle")
struct AudioEngineLifecycleTests {
    @Test("Start activates the session before preparing and starting the engine")
    func startOrdersLifecycleAndReachesRunning() async throws {
        // Arrange
        let recorder = TestDoubles.CommandRecorder()
        let session = TestDoubles.AudioSessionBackend(recorder: recorder)
        let engine = TestDoubles.AudioEngineBackend(recorder: recorder)
        let control = AudioControlActor(backend: session, engineBackend: engine)

        // Act
        try await control.start()

        // Assert
        #expect(await control.state == .running)
        #expect(recorder.commands == Fixtures.startCommands)
    }

    @Test("Repeated start and stop calls are idempotent")
    func repeatedLifecycleCallsAreIdempotent() async throws {
        // Arrange
        let recorder = TestDoubles.CommandRecorder()
        let control = AudioControlActor(
            backend: TestDoubles.AudioSessionBackend(recorder: recorder),
            engineBackend: TestDoubles.AudioEngineBackend(recorder: recorder)
        )

        // Act
        try await control.start()
        try await control.start()
        try await control.stop()
        try await control.stop()

        // Assert
        #expect(await control.state == .stopped)
        #expect(recorder.commands == Fixtures.lifecycleCommands)
    }

    @Test(
        "Start failures deactivate the session and publish a typed failed state",
        arguments: Fixtures.startFailureCases
    )
    fileprivate func startFailuresCleanUp(testCase: Fixtures.StartFailureCase) async {
        // Arrange
        let recorder = TestDoubles.CommandRecorder()
        let session = TestDoubles.AudioSessionBackend(
            recorder: recorder,
            failsActivation: testCase.failure == .sessionActivation
        )
        let engine = TestDoubles.AudioEngineBackend(
            recorder: recorder,
            failure: testCase.failure.engineFailure
        )
        let control = AudioControlActor(backend: session, engineBackend: engine)
        var receivedFailure: AudioEngineFailure?

        // Act
        do {
            try await control.start()
        } catch {
            receivedFailure = error
        }

        // Assert
        #expect(receivedFailure == testCase.expectedFailure)
        #expect(await control.state == .failed(testCase.expectedFailure))
        #expect(recorder.commands == testCase.expectedCommands)
    }

    @Test("Stop stops the engine before deactivating the session")
    func stopOrdersLifecycleAndReachesStopped() async throws {
        // Arrange
        let recorder = TestDoubles.CommandRecorder()
        let session = TestDoubles.AudioSessionBackend(recorder: recorder)
        let engine = TestDoubles.AudioEngineBackend(recorder: recorder)
        let control = AudioControlActor(backend: session, engineBackend: engine)
        try await control.start()
        recorder.reset()

        // Act
        try await control.stop()

        // Assert
        #expect(await control.state == .stopped)
        #expect(recorder.commands == [.engineStop, .sessionDeactivate])
    }

    @Test("A session deactivation failure leaves a typed failed state")
    func stopMapsDeactivationFailure() async throws {
        // Arrange
        let recorder = TestDoubles.CommandRecorder()
        let session = TestDoubles.AudioSessionBackend(recorder: recorder)
        let engine = TestDoubles.AudioEngineBackend(recorder: recorder)
        let control = AudioControlActor(backend: session, engineBackend: engine)
        try await control.start()
        recorder.reset()
        session.failsDeactivation = true
        var receivedFailure: AudioEngineFailure?

        // Act
        do {
            try await control.stop()
        } catch {
            receivedFailure = error
        }

        // Assert
        let expectedFailure = AudioEngineFailure.sessionDeactivation(.deactivationFailed)
        #expect(receivedFailure == expectedFailure)
        #expect(await control.state == .failed(expectedFailure))
        #expect(recorder.commands == [.engineStop, .sessionDeactivate])
    }
}

private enum Fixtures {
    enum StartFailurePoint: Equatable, Sendable {
        case sessionActivation
        case enginePreparation
        case engineStart

        var engineFailure: TestDoubles.AudioEngineBackend.FailurePoint? {
            switch self {
            case .sessionActivation: nil
            case .enginePreparation: .prepare
            case .engineStart: .start
            }
        }
    }

    struct StartFailureCase: Sendable, CustomTestStringConvertible {
        let description: String
        let failure: StartFailurePoint
        let expectedFailure: AudioEngineFailure
        let expectedCommands: [TestDoubles.Command]

        var testDescription: String { description }
    }

    static let sessionActivationCommands: [TestDoubles.Command] = [
        .sessionConfigure,
        .sessionPreferredSampleRate(48_000),
        .sessionPreferredBufferDuration(0.00533),
        .sessionActivate
    ]

    static let startCommands = sessionActivationCommands + [
        .enginePrepare,
        .engineStart
    ]

    static let lifecycleCommands = startCommands + [
        .engineStop,
        .sessionDeactivate
    ]

    static let startFailureCases = [
        StartFailureCase(
            description: "session activation",
            failure: .sessionActivation,
            expectedFailure: .sessionActivation(.activationFailed),
            expectedCommands: sessionActivationCommands + [.sessionDeactivate]
        ),
        StartFailureCase(
            description: "engine preparation",
            failure: .enginePreparation,
            expectedFailure: .preparationFailed,
            expectedCommands: sessionActivationCommands + [
                .enginePrepare,
                .engineStop,
                .sessionDeactivate
            ]
        ),
        StartFailureCase(
            description: "engine start",
            failure: .engineStart,
            expectedFailure: .startFailed,
            expectedCommands: startCommands + [
                .engineStop,
                .sessionDeactivate
            ]
        )
    ]
}

private enum TestDoubles {
    enum Command: Equatable, Sendable {
        case sessionConfigure
        case sessionPreferredSampleRate(Double)
        case sessionPreferredBufferDuration(TimeInterval)
        case sessionActivate
        case sessionDeactivate
        case enginePrepare
        case engineStart
        case engineStop
    }

    final class CommandRecorder: @unchecked Sendable {
        private let lock = NSLock()
        private var recordedCommands: [Command] = []

        var commands: [Command] {
            lock.withLock { recordedCommands }
        }

        func append(_ command: Command) {
            lock.withLock { recordedCommands.append(command) }
        }

        func reset() {
            lock.withLock { recordedCommands = [] }
        }
    }

    final class AudioSessionBackend: BassPractice.AudioSessionBackend, @unchecked Sendable {
        enum Failure: Error {
            case requested
        }

        private let recorder: CommandRecorder
        private let failsActivation: Bool
        private let lock = NSLock()
        private var shouldFailDeactivation = false

        let sampleRate = 48_000.0
        let ioBufferDuration: TimeInterval = 0.00533
        let currentRoute = AudioRoute.empty
        let availableInputs: [AudioInput] = []
        let events = AsyncStream<AudioSessionBackendEvent> { _ in }

        var failsDeactivation: Bool {
            get { lock.withLock { shouldFailDeactivation } }
            set { lock.withLock { shouldFailDeactivation = newValue } }
        }

        init(recorder: CommandRecorder, failsActivation: Bool = false) {
            self.recorder = recorder
            self.failsActivation = failsActivation
        }

        func configureForMeasurement() {
            recorder.append(.sessionConfigure)
        }

        func setPreferredSampleRate(_ sampleRate: Double) {
            recorder.append(.sessionPreferredSampleRate(sampleRate))
        }

        func setPreferredIOBufferDuration(_ duration: TimeInterval) {
            recorder.append(.sessionPreferredBufferDuration(duration))
        }

        func setActive(_ active: Bool, notifyOthersOnDeactivation: Bool) throws {
            recorder.append(active ? .sessionActivate : .sessionDeactivate)
            if active && failsActivation {
                throw Failure.requested
            }
            if !active && failsDeactivation {
                throw Failure.requested
            }
        }

        func setPreferredInput(id: String?) {}
    }

    final class AudioEngineBackend: BassPractice.AudioEngineBackend, @unchecked Sendable {
        enum FailurePoint: Equatable, Sendable {
            case prepare
            case start
        }

        enum Failure: Error {
            case requested
        }

        private let recorder: CommandRecorder
        private let failure: FailurePoint?

        init(recorder: CommandRecorder, failure: FailurePoint? = nil) {
            self.recorder = recorder
            self.failure = failure
        }

        func prepare() throws {
            recorder.append(.enginePrepare)
            if failure == .prepare {
                throw Failure.requested
            }
        }

        func start() throws {
            recorder.append(.engineStart)
            if failure == .start {
                throw Failure.requested
            }
        }

        func stop() {
            recorder.append(.engineStop)
        }
    }
}
