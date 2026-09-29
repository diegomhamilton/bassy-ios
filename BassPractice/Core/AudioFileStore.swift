import Foundation

protocol AudioFileStore {
    var rootDirectory: URL { get }
}

struct LocalAudioFileStore: AudioFileStore {
    let rootDirectory: URL

    init(fileManager: FileManager = .default) {
        rootDirectory = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? fileManager.temporaryDirectory
    }
}
