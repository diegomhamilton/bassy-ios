import Foundation

struct AudioDevice: Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    let portType: String
}

struct AudioRoute: Equatable, Sendable {
    let inputs: [AudioDevice]
    let outputs: [AudioDevice]

    static let empty = AudioRoute(inputs: [], outputs: [])
}

enum AudioRouteChangeReason: Equatable, Sendable {
    case unknown
    case newDeviceAvailable
    case oldDeviceUnavailable
    case categoryChange
    case override
    case wakeFromSleep
    case noSuitableRouteForCategory
    case routeConfigurationChange
    case unrecognized(UInt)
}

enum AudioSessionEvent: Equatable, Sendable {
    case mediaChanged
    case mixerChanged
    case routeChanged(route: AudioRoute, reason: AudioRouteChangeReason)
    case interruptionBegan
    case interruptionEnded(shouldResume: Bool)
    case enteredBackground
    case enteredForeground
}
