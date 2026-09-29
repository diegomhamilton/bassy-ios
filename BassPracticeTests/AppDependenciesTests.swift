import XCTest
@testable import BassPractice

final class AppDependenciesTests: XCTestCase {
    func testDependenciesCanBeReplacedWithTestDoubles() {
        let audioEngine = AudioEngineSpy()
        let sessions = SessionRepositoryStub()
        let files = AudioFileStoreStub()

        let dependencies = AppDependencies(
            audioEngine: audioEngine,
            sessionRepository: sessions,
            audioFileStore: files,
            logger: AppLogger()
        )

        XCTAssertTrue(dependencies.audioEngine === audioEngine)
        XCTAssertEqual(dependencies.sessionRepository.sessions(), sessions.result)
        XCTAssertEqual(dependencies.audioFileStore.rootDirectory, files.rootDirectory)
    }

    func testInitialDestinationDefaultsToSession() {
        XCTAssertEqual(AppDestination.initial(arguments: []), .session)
    }

    func testInitialDestinationReadsLaunchArgument() {
        XCTAssertEqual(
            AppDestination.initial(arguments: ["BassPractice", "-initial-tab", "library"]),
            .library
        )
    }
}

private final class AudioEngineSpy: AudioEngineProtocol {
    let status: AudioEngineStatus = .idle
}

private final class SessionRepositoryStub: SessionRepository {
    let result = [PracticeSession(id: UUID(), name: "Test Session")]

    func sessions() -> [PracticeSession] {
        result
    }
}

private struct AudioFileStoreStub: AudioFileStore {
    let rootDirectory = URL(fileURLWithPath: "/tmp/bass-practice-tests")
}
