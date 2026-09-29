import SwiftUI

struct LibraryView: View {
    let sessionRepository: any SessionRepository

    var body: some View {
        Group {
            if sessionRepository.sessions().isEmpty {
                ContentUnavailableView {
                    Label("No Sessions Yet", systemImage: "music.note.list")
                } description: {
                    Text("Saved practice sessions will appear here.")
                }
            } else {
                List(sessionRepository.sessions()) { session in
                    Text(session.name)
                }
            }
        }
        .navigationTitle("Library")
    }
}
