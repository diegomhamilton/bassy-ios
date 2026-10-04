import Foundation

struct AppDependencies {
    let audioSession: any AudioSessionManaging
    let audioEngine: any AudioEngineProtocol
    let sessionRepository: any SessionRepository
    let audioFileStore: any AudioFileStore
    let logger: AppLogger

    static func live() -> AppDependencies {
        let audioControl = AudioControlActor(
            backend: SystemAudioSessionBackend(),
            engineBackend: SystemAudioEngineBackend()
        )
        return AppDependencies(
            audioSession: audioControl,
            audioEngine: audioControl,
            sessionRepository: InMemorySessionRepository(),
            audioFileStore: LocalAudioFileStore(),
            logger: AppLogger()
        )
    }
}
