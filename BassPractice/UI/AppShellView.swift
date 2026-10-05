import SwiftUI

enum AppDestination: String, CaseIterable {
    case session
    case tone
    case library

    static func initial(arguments: [String]) -> AppDestination {
        guard let flagIndex = arguments.firstIndex(of: "-initial-tab"),
              arguments.indices.contains(flagIndex + 1),
              let destination = AppDestination(rawValue: arguments[flagIndex + 1]) else {
            return .session
        }

        return destination
    }
}

struct AppShellView: View {
    let dependencies: AppDependencies
    @State private var selection: AppDestination

    init(
        dependencies: AppDependencies,
        initialDestination: AppDestination = .initial(arguments: ProcessInfo.processInfo.arguments)
    ) {
        self.dependencies = dependencies
        _selection = State(initialValue: initialDestination)
    }

    var body: some View {
        TabView(selection: $selection) {
            NavigationStack {
                SessionView(audioEngine: dependencies.audioEngine, audioSession: dependencies.audioSession)
            }
            .tabItem {
                Label("Session", systemImage: "waveform")
            }
            .tag(AppDestination.session)

            NavigationStack {
                ToneView()
            }
            .tabItem {
                Label("Tone", systemImage: "slider.horizontal.3")
            }
            .tag(AppDestination.tone)

            NavigationStack {
                LibraryView(sessionRepository: dependencies.sessionRepository)
            }
            .tabItem {
                Label("Library", systemImage: "music.note.list")
            }
            .tag(AppDestination.library)
        }
    }
}

#Preview {
    AppShellView(dependencies: .live())
}
