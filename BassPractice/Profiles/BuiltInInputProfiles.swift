import Foundation

/// Neutral starting points. Instrument-specific DSP presets are supplied separately.
enum BuiltInInputProfiles {
    // These identifiers are persisted identity, so retain them when changing display names.
    static let bassID = UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1))
    static let guitarID = UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2))
    static let customID = UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3))

    static let profiles: [InputProfile] = {
        do {
            return [
                try InputProfile(id: bassID, name: "Bass", instrument: .bass),
                try InputProfile(id: guitarID, name: "Guitar", instrument: .guitar),
                try InputProfile(id: customID, name: "Flat / Custom", instrument: .custom)
            ]
        } catch {
            // Literal names and domain defaults must satisfy the validated model.
            // A failure here is a programming error, never malformed user data.
            preconditionFailure("Invalid built-in input profile constants: \(error)")
        }
    }()
}
