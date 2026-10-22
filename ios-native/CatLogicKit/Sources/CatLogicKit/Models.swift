import Foundation
import Observation

// Screen state, kept out of the SwiftUI views so it can be tested without a
// simulator. Views only draw these and forward taps.

@MainActor @Observable
public final class AppModel {
    public let store: GameStore
    public let leaderboard: LeaderboardService
    public let now: () -> Date
    public var settings: Settings {
        didSet { store.settings = settings }
    }

    public init(store: GameStore, leaderboard: LeaderboardService, now: @escaping () -> Date = Date.init) {
        self.store = store
        self.leaderboard = leaderboard
        self.now = now
        settings = store.settings
    }

    public var today: String { Daily.todayKey(now()) }

    // A daily solved while offline or signed out is sent later, but only while
    // it's still that day: the leaderboard only takes times for the current day.
    @discardableResult
    public func submitPendingDaily() async -> Bool {
        let date = today
        guard let rec = store.daily(date), rec.status == .solved, !rec.submitted,
              let size = try? Daily.puzzle(for: date).size,
              Daily.isPlausible(timeMs: rec.timeMs, size: size) else { return false }
        do {
            _ = try await leaderboard.submitDaily(date: date, timeMs: rec.timeMs, mistakes: rec.mistakes)
            var sent = rec
            sent.submitted = true
            store.recordDaily(sent)
            return true
        } catch {
            return false
        }
    }

    public static func live(leaderboard: LeaderboardService) -> AppModel {
        AppModel(store: FileStore.standard(), leaderboard: leaderboard)
    }

    public static func preview() -> AppModel {
        let m = AppModel(store: FileStore(url: nil), leaderboard: SampleLeaderboard())
        m.store.setFlag("seenTutorial", true)
        return m
    }
}

public enum PuzzleRoute: Hashable, Sendable {
    case level(Int)
    case daily(String)
}

public enum Feedback: Equatable, Sendable {
    case none, place, mistake, solved
}

@MainActor @Observable
public final class PuzzleSession {
    public struct Result: Equatable, Sendable {
        public var timeMs: Int
        public var bestMs: Int?
        public var rank: Int?
        public var total: Int?
    }

    public let kind: PuzzleKind
    public let key: String
    public let puzzle: SolvedPuzzle
    public let title: String
    public private(set) var game: Game
    public private(set) var hints: Int
    public private(set) var solvedBefore: DailyRecord?
    public private(set) var result: Result?
    public private(set) var feedback = Feedback.none
    public private(set) var feedbackCount = 0 // changes on every event, for sensoryFeedback
    public private(set) var submitNote: String? // why a daily time wasn't posted
    public private(set) var submitTask: Task<Void, Never>?

    private let app: AppModel
    private var elapsedMs = 0
    private var runningSince: Date?
    private var visible = false
    private var sheetOpen = false

    // nil when the route doesn't exist or the daily is from another day
    public init?(route: PuzzleRoute, app: AppModel) {
        self.app = app
        switch route {
        case .level(let n):
            guard let p = LevelPack.level(n) else { return nil }
            kind = .level
            key = String(n)
            puzzle = p
            title = "Level \(n)"
        case .daily(let date):
            guard date == app.today, let p = try? Daily.puzzle(for: date) else { return nil }
            kind = .daily
            key = date
            puzzle = p
            title = "Daily"
        }
        game = Game(puzzle: puzzle)
        hints = app.store.hints
        if kind == .daily, let rec = app.store.daily(key), rec.status == .solved {
            solvedBefore = rec
            game.cells = puzzle.regions.indices.map { puzzle.isAnswer($0) ? .cat : .empty }
            game.status = .solved
        } else if let saved = app.store.attempt(kind, key), saved.cells.count == puzzle.size * puzzle.size {
            game.cells = saved.cells
            game.history = saved.history
            game.lives = saved.lives
            game.mistakes = saved.mistakes
            elapsedMs = saved.elapsedMs
        }
    }

    // MARK: timer — runs only while the board is on screen, the app is
    // active and no sheet is open

    public func elapsed(at date: Date? = nil) -> Int {
        if let solvedBefore { return solvedBefore.timeMs }
        let now = date ?? app.now()
        return elapsedMs + (runningSince.map { Int(now.timeIntervalSince($0) * 1000) } ?? 0)
    }

    public func setVisible(_ on: Bool) {
        visible = on
        updateClock()
    }

    public func setSheetOpen(_ on: Bool) {
        sheetOpen = on
        updateClock()
    }

    private func updateClock() {
        let shouldRun = visible && !sheetOpen && game.status == .playing && solvedBefore == nil
        let now = app.now()
        if shouldRun, runningSince == nil {
            runningSince = now
        } else if !shouldRun, let since = runningSince {
            elapsedMs += Int(now.timeIntervalSince(since) * 1000)
            runningSince = nil
        }
    }

    // MARK: play

    public func act(_ action: GameAction) {
        let before = game
        game.apply(action)
        if game.lives < before.lives {
            emit(.mistake)
        } else if game.status == .solved, before.status != .solved {
            emit(.solved)
        } else if game.cells != before.cells {
            emit(.place)
        }
        afterMove()
    }

    // A level restarts the clock; the daily keeps counting so retries are fair.
    public func restart() {
        if kind == .level {
            elapsedMs = 0
            if runningSince != nil { runningSince = app.now() }
        }
        act(.restart)
        updateClock()
    }

    public func spendHint() {
        guard hints > 0, game.status == .playing else { return }
        hints = app.store.addHints(-1)
        act(.hint)
    }

    private func emit(_ f: Feedback) {
        feedback = f
        feedbackCount += 1
    }

    private func afterMove() {
        switch game.status {
        case .playing:
            app.store.saveAttempt(SavedAttempt(kind: kind, key: key, cells: game.cells, history: game.history,
                                               lives: game.lives, mistakes: game.mistakes, elapsedMs: elapsed()))
        case .failed:
            updateClock()
        case .solved:
            updateClock()
            finish()
        }
    }

    private func finish() {
        let ms = elapsed()
        app.store.clearAttempt(kind, key)
        if kind == .level {
            let rec = app.store.recordLevelSolve(Int(key)!, ms: ms)
            result = Result(timeMs: ms, bestMs: rec.bestMs)
            return
        }
        hints = app.store.addHints(1)
        result = Result(timeMs: ms)
        let (date, mistakes, store, board) = (key, game.mistakes, app.store, app.leaderboard)
        store.recordDaily(DailyRecord(date: date, status: .solved, timeMs: ms, mistakes: mistakes, submitted: false))
        guard Daily.isPlausible(timeMs: ms, size: puzzle.size) else {
            submitNote = "This time is too fast to post to the leaderboard."
            return
        }
        submitTask = Task {
            do {
                let placed = try await board.submitDaily(date: date, timeMs: ms, mistakes: mistakes)
                store.recordDaily(DailyRecord(date: date, status: .solved, timeMs: ms, mistakes: mistakes, submitted: true))
                if let placed { self.result = Result(timeMs: ms, rank: placed.rank, total: placed.total) }
            } catch SubmitError.signedOut {
                self.submitNote = "Sign in to Game Center to post your time. It's saved until then."
            } catch {
                self.submitNote = "Your time is saved and will post when you're back online."
            }
        }
    }

    public var nextLevel: Int? {
        guard kind == .level, let n = Int(key), n < LevelPack.count else { return nil }
        return n + 1
    }
}

@MainActor @Observable
public final class HomeModel {
    public private(set) var today = ""
    public private(set) var daily: DailyRecord?
    public private(set) var streak = 0
    public private(set) var solved = 0
    public private(set) var next = 1
    public private(set) var needsTutorial = false
    private let app: AppModel

    public init(app: AppModel) {
        self.app = app
        reload()
    }

    public func reload() {
        today = app.today
        daily = app.store.daily(today)
        streak = app.store.dailyStreak(today: today)
        solved = app.store.levels.count
        next = Swift.min(LevelPack.count, (app.store.levels.keys.max() ?? 0) + 1)
        needsTutorial = !app.store.flag("seenTutorial")
    }

    public var dailySize: Int { (try? Daily.puzzle(for: today))?.size ?? 0 }
    public var nextSize: Int { LevelPack.level(next)?.size ?? minSize }
}

@MainActor @Observable
public final class LeaderboardModel {
    public enum State: Equatable {
        case loading
        case loaded(LeaderboardResult)
    }

    public static let top = 50
    public private(set) var state = State.loading
    public private(set) var mine: DailyRecord?
    public let date: String
    private let app: AppModel

    public init(app: AppModel) {
        self.app = app
        date = app.today
    }

    public func load() async {
        state = .loading
        await app.submitPendingDaily()
        mine = app.store.daily(date)
        let solved = mine?.status == .solved ? mine?.timeMs : nil
        state = .loaded(await app.leaderboard.daily(date: date, myTimeMs: solved))
    }

    public var visibleRows: [LeaderboardRow] {
        guard case .loaded(.ok(let rows, _)) = state else { return [] }
        return rows.filter { $0.rank <= Self.top || $0.isMe }
    }
}
