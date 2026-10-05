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
    @State private var sessionModel: SessionModel

    init(
        dependencies: AppDependencies,
        initialDestination: AppDestination = .initial(arguments: ProcessInfo.processInfo.arguments)
    ) {
        self.dependencies = dependencies
        _selection = State(initialValue: initialDestination)
        _sessionModel = State(initialValue: SessionModel(engine: dependencies.audioEngine, session: dependencies.audioSession, files: dependencies.audioFileStore, repository: dependencies.sessionRepository))
    }

    var body: some View {
        TabView(selection: $selection) {
            NavigationStack {
                SessionView(model: sessionModel, toneController: dependencies.gainController, profileRepository: dependencies.profileRepository)
            }
            .tabItem {
                Label("Session", systemImage: "waveform")
            }
            .tag(AppDestination.session)

            NavigationStack {
                ToneView(controller: dependencies.gainController, profileRepository: dependencies.profileRepository)
                    .id(sessionModel.practiceSessionID)
            }
            .tabItem {
                Label("Tone", systemImage: "slider.horizontal.3")
            }
            .tag(AppDestination.tone)

            NavigationStack {
                LibraryView(sessionRepository: dependencies.sessionRepository, workspace: sessionModel)
            }
            .tabItem {
                Label("Library", systemImage: "music.note.list")
            }
            .tag(AppDestination.library)
        }
        .task { await sessionModel.observe() }
        .disabled(!sessionModel.isWorkspaceReady || sessionModel.isBusy)
    }
}

#Preview {
    AppShellView(dependencies: .live())
}
