import AVFoundation
import Foundation

enum AudioPlaybackFailure: Error, Equatable, Sendable {
    case engineUnavailable, unsupportedBackend, unreadableFile, invalidFormat, startFailed
    var message: String {
        switch self {
        case .engineUnavailable: "Start audio to play this recording."
        case .unsupportedBackend: "Playback is unavailable."
        case .unreadableFile: "The recording file could not be opened."
        case .invalidFormat: "This recording has no readable audio."
        case .startFailed: "Audio playback could not start. Try again."
        }
    }
}

enum AudioPlaybackState: Equatable, Sendable {
    case stopped
    case playing(UUID)
    case failed(AudioPlaybackFailure)
}

protocol AudioPlaybackControlling: AnyObject, Sendable {
    var playbackState: AudioPlaybackState { get async }
    func play(_ recording: Recording) async throws(AudioPlaybackFailure)
    func stopPlayback() async
}

protocol AudioPlaybackBackend: AudioEngineBackend {
    func play(fileURL: URL, completion: @escaping @Sendable () async -> Void) throws(AudioPlaybackFailure)
    func stopPlayback()
}
