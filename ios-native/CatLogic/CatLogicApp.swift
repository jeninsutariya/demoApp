import CatLogicKit
import SwiftUI

@main
struct CatLogicApp: App {
    @State private var app = AppModel.live()
    @State private var router = Router()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(app)
                .environment(router)
        }
    }
}

enum Route: Hashable {
    case puzzle(PuzzleRoute)
    case levels, leaderboard, settings, design
}

@MainActor @Observable
final class Router {
    var path: [Route] = []
    var showTutorial = false

    func push(_ r: Route) { path.append(r) }

    // Swap the current screen, e.g. "next level" from the win sheet
    func replaceTop(_ r: Route) {
        if path.isEmpty { path.append(r) } else { path[path.count - 1] = r }
    }

    func home() { path.removeAll() }
}

struct RootView: View {
    @Environment(Router.self) private var router

    var body: some View {
        @Bindable var router = router
        NavigationStack(path: $router.path) {
            HomeView()
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .puzzle(let p): PuzzleScreen(route: p).id(p)
                    case .levels: LevelsView()
                    case .leaderboard: LeaderboardView()
                    case .settings: SettingsView()
                    case .design: DesignView()
                    }
                }
        }
        .tint(Tokens.Colors.accent)
        .fullScreenCover(isPresented: $router.showTutorial) {
            HowToPlayView()
        }
    }
}
