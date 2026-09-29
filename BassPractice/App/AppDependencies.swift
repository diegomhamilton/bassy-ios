import Foundation

struct AppDependencies {
    let audioEngine: any AudioEngineProtocol
    let sessionRepository: any SessionRepository
    let audioFileStore: any AudioFileStore
    let logger: AppLogger

    static func live() -> AppDependencies {
        AppDependencies(
            audioEngine: PreviewAudioEngine(),
            sessionRepository: InMemorySessionRepository(),
            audioFileStore: LocalAudioFileStore(),
            logger: AppLogger()
        )
    }
}
