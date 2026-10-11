import Foundation
import Testing
@testable import BassPractice

@Suite("App dependencies")
struct AppDependenciesTests {
    @Test("Dependencies can be replaced with test doubles")
    func dependenciesCanBeReplacedWithTestDoubles() async {
        // Arrange
        let audioSession = TestDoubles.AudioSession()
        let audioEngine = TestDoubles.AudioEngine()
        let sessions = TestDoubles.SessionRepository()
        let files = TestDoubles.AudioFileStore()

        // Act
        let dependencies = AppDependencies(
            audioSession: audioSession,
            audioEngine: audioEngine,
            sessionRepository: sessions,
            audioFileStore: files,
            logger: AppLogger()
        )

        // Assert
        #expect(dependencies.audioSession === audioSession)
        #expect(dependencies.audioEngine === audioEngine)
        #expect(dependencies.sessionRepository.sessions() == sessions.result)
        #expect(dependencies.audioFileStore.rootDirectory == files.rootDirectory)
    }

    @Test(
        "Initial destination follows supported launch arguments",
        arguments: Fixtures.destinationCases
    )
    fileprivate func initialDestination(testCase: Fixtures.DestinationCase) {
        // Arrange
        let arguments = testCase.arguments

        // Act
        let destination = AppDestination.initial(arguments: arguments)

        // Assert
        #expect(destination == testCase.expectedDestination)
    }
}

private enum Fixtures {
    struct DestinationCase: Sendable {
        let arguments: [String]
        let expectedDestination: AppDestination
    }

    static let destinationCases = [
        DestinationCase(arguments: [], expectedDestination: .session),
        DestinationCase(
            arguments: ["BassPractice", "-initial-tab", "library"],
            expectedDestination: .library
        )
    ]
}

private enum TestDoubles {
    actor AudioSession: AudioSessionManaging {
        let currentRoute = AudioRoute.empty
        let availableInputs: [AudioInput] = []
        let preferredInput: AudioInput? = nil

        private(set) var snapshot = AudioSessionSnapshot(
            requestedSampleRate: 48_000,
            requestedIOBufferDuration: 0.00533,
            actualSampleRate: nil,
            actualIOBufferDuration: nil,
            isActive: false
        )

        func activate() -> AudioSessionSnapshot {
            snapshot
        }

        func deactivate() {}

        func selectPreferredInput(id: String?) {}

        func events() -> AsyncStream<AudioSessionEvent> {
            AsyncStream { _ in }
        }
    }

    final class AudioEngine: AudioEngineProtocol {
        let status: AudioEngineStatus = .idle
    }

    final class SessionRepository: BassPractice.SessionRepository {
        let result = [PracticeSession(id: UUID(), name: "Test Session")]

        func sessions() -> [PracticeSession] {
            result
        }
    }

    struct AudioFileStore: BassPractice.AudioFileStore {
        let rootDirectory = URL(fileURLWithPath: "/tmp/bass-practice-tests")
    }
}
