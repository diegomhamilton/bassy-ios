import Foundation

struct AppDependencies {
    let audioSession: any AudioSessionManaging
    let audioEngine: any AudioEngineProtocol
    let sessionRepository: any SessionRepository
    let audioFileStore: any AudioFileStore
    let logger: AppLogger

    static func live() -> AppDependencies {
        AppDependencies(
            audioSession: AudioControlActor(backend: SystemAudioSessionBackend()),
            audioEngine: PreviewAudioEngine(),
            sessionRepository: InMemorySessionRepository(),
            audioFileStore: LocalAudioFileStore(),
            logger: AppLogger()
        )
    }
}
