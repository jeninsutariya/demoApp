import CatLogicKit
import SwiftUI

@main
struct CatLogicApp: App {
    @State private var app = AppModel.live(leaderboard: CatLogicApp.leaderboard())
    @State private var router = Router()
    @State private var gameCenter = GameCenterAuth()
    @State private var purchases = Purchases()

    // Launch with -sampleLeaderboard (Xcode scheme > Arguments) to use sample
    // players, e.g. before the App Store Connect leaderboard exists.
    static func leaderboard() -> LeaderboardService {
        ProcessInfo.processInfo.arguments.contains("-sampleLeaderboard") ? SampleLeaderboard() : GameCenterLeaderboard()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(app)
                .environment(router)
                .environment(gameCenter)
                .environment(purchases)
                .task {
                    purchases.start(app: app)
                    gameCenter.start {
                        Task { await app.submitPendingDaily() }
                    }
                }
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
    var showUnlock = false

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
        .sheet(isPresented: $router.showUnlock) {
            UnlockView()
        }
    }
}
