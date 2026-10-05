import Foundation

struct AppDependencies {
    let audioSession: any AudioSessionManaging
    let audioEngine: any AudioEngineProtocol
    let gainController: any AudioToneControlling
    let profileRepository: any InputProfileRepository
    let sessionRepository: any SessionRepository
    let audioFileStore: any AudioFileStore
    let logger: AppLogger

    static func live() -> AppDependencies {
        let profiles: any InputProfileRepository
        do { profiles = try FileInputProfileRepository.live() }
        catch { profiles = UnavailableInputProfileRepository(failure: error) }
        let audioControl = AudioControlActor(
            backend: SystemAudioSessionBackend(),
            engineBackend: SystemAudioEngineBackend()
        )
        return AppDependencies(
            audioSession: audioControl,
            audioEngine: audioControl,
            gainController: audioControl,
            profileRepository: profiles,
            sessionRepository: InMemorySessionRepository(),
            audioFileStore: LocalAudioFileStore(),
            logger: AppLogger()
        )
    }
}
