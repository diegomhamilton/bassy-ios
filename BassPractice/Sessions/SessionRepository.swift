import Foundation

struct PracticeSession: Identifiable, Equatable {
    let id: UUID
    var name: String
}

protocol SessionRepository: AnyObject {
    func sessions() -> [PracticeSession]
}

final class InMemorySessionRepository: SessionRepository {
    private var storedSessions: [PracticeSession]

    init(sessions: [PracticeSession] = []) {
        storedSessions = sessions
    }

    func sessions() -> [PracticeSession] {
        storedSessions
    }
}
