import Foundation

protocol AudioEngineProtocol: AnyObject {
    var status: AudioEngineStatus { get }
}

enum AudioEngineStatus: Equatable {
    case idle
}

final class PreviewAudioEngine: AudioEngineProtocol {
    let status: AudioEngineStatus = .idle
}
