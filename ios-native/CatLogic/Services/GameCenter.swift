import CatLogicKit
import GameKit
import UIKit

enum GameCenter {
    // Must match the recurring leaderboard in App Store Connect (see replica/backend.md)
    static let dailyLeaderboardID = "catlogic.daily.fastest"
    static let pageSize = 50

    static func isOffline(_ error: Error) -> Bool {
        let ns = error as NSError
        return ns.domain == NSURLErrorDomain || (error as? GKError)?.code == .communicationsFailure
    }

    static func isSignedOut(_ error: Error) -> Bool {
        (error as? GKError)?.code == .notAuthenticated
    }

    @MainActor static func topViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        var top = scene?.keyWindow?.rootViewController
        while let presented = top?.presentedViewController { top = presented }
        return top
    }
}

// The daily leaderboard on Game Center: a recurring leaderboard that resets
// every day at 00:00 UTC, sorted low to high, scores in hundredths of a second.
// Main actor because GameKit's local player lives there.
@MainActor
final class GameCenterLeaderboard: LeaderboardService {
    let leaderboardID: String

    init(leaderboardID: String = GameCenter.dailyLeaderboardID) {
        self.leaderboardID = leaderboardID
    }

    func submitDaily(date: String, timeMs: Int, mistakes: Int) async throws -> (rank: Int, total: Int)? {
        let player = GKLocalPlayer.local
        guard player.isAuthenticated else { throw SubmitError.signedOut }
        do {
            // context records the generator version and mistakes, for later checks
            try await GKLeaderboard.submitScore(timeMs / 10, context: Generator.generatorVersion * 100 + mistakes,
                                                player: player, leaderboardIDs: [leaderboardID])
        } catch {
            if GameCenter.isSignedOut(error) { throw SubmitError.signedOut }
            if GameCenter.isOffline(error) { throw SubmitError.offline }
            throw SubmitError.failed(error.localizedDescription)
        }
        // The new score can take a moment to show up; no rank is fine.
        guard let board = try? await GKLeaderboard.loadLeaderboards(IDs: [leaderboardID]).first,
              let loaded = try? await board.loadEntries(for: .global, timeScope: .today, range: NSRange(location: 1, length: 1)),
              let mine = loaded.0 else { return nil }
        return (mine.rank, loaded.2)
    }

    func daily(date: String, myTimeMs: Int?) async -> LeaderboardResult {
        let me = GKLocalPlayer.local
        guard me.isAuthenticated else { return .signedOut }
        do {
            guard let board = try await GKLeaderboard.loadLeaderboards(IDs: [leaderboardID]).first else {
                return .error("The daily leaderboard isn't set up in App Store Connect yet.")
            }
            let (mine, entries, _) = try await board.loadEntries(for: .global, timeScope: .today,
                                                                 range: NSRange(location: 1, length: GameCenter.pageSize))
            var rows = entries.map {
                LeaderboardRow(rank: $0.rank, name: $0.player.displayName, timeMs: $0.score * 10,
                               isMe: $0.player.gamePlayerID == me.gamePlayerID)
            }
            if let mine, !rows.contains(where: \.isMe) {
                rows.append(LeaderboardRow(rank: mine.rank, name: mine.player.displayName, timeMs: mine.score * 10, isMe: true))
            }
            return .ok(rows: rows, sample: false)
        } catch {
            if GameCenter.isSignedOut(error) { return .signedOut }
            return GameCenter.isOffline(error) ? .offline : .error(error.localizedDescription)
        }
    }
}

// Signs the player in to Game Center once at launch. Apple shows its own
// sign-in sheet when needed; players who skip it can still play everything.
@MainActor @Observable
final class GameCenterAuth {
    private(set) var isSignedIn = false
    private(set) var playerName: String?
    private var started = false

    func start(onSignIn: @escaping @MainActor () -> Void) {
        guard !started else { return }
        started = true
        GKLocalPlayer.local.authenticateHandler = { viewController, _ in
            Task { @MainActor in
                if let viewController {
                    GameCenter.topViewController()?.present(viewController, animated: true)
                    return
                }
                let player = GKLocalPlayer.local
                self.isSignedIn = player.isAuthenticated
                self.playerName = player.isAuthenticated ? player.displayName : nil
                if player.isAuthenticated { onSignIn() }
            }
        }
    }

    // Apple's own leaderboard screen (friends, past days)
    func showDashboard() {
        let vc = GKGameCenterViewController(leaderboardID: GameCenter.dailyLeaderboardID, playerScope: .global, timeScope: .today)
        vc.gameCenterDelegate = Dismisser.shared
        GameCenter.topViewController()?.present(vc, animated: true)
    }

    private final class Dismisser: NSObject, GKGameCenterControllerDelegate {
        static let shared = Dismisser()
        func gameCenterViewControllerDidFinish(_ vc: GKGameCenterViewController) {
            vc.dismiss(animated: true)
        }
    }
}
