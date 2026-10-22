import Foundation
import XCTest
@testable import CatLogicKit

// A leaderboard that can be signed out or offline, and records what it got.
final class FakeBoard: LeaderboardService, @unchecked Sendable {
    enum Mode { case ok, offline, signedOut }
    var mode = Mode.ok
    var posted: [(date: String, timeMs: Int)] = []

    func submitDaily(date: String, timeMs: Int, mistakes: Int) async throws -> (rank: Int, total: Int)? {
        switch mode {
        case .offline: throw SubmitError.offline
        case .signedOut: throw SubmitError.signedOut
        case .ok:
            posted.append((date, timeMs))
            return (1, posted.count)
        }
    }

    func daily(date: String, myTimeMs: Int?) async -> LeaderboardResult {
        switch mode {
        case .offline: .offline
        case .signedOut: .signedOut
        case .ok: .ok(rows: posted.enumerated().map { LeaderboardRow(rank: $0.offset + 1, name: "P", timeMs: $0.element.timeMs, isMe: true) }, sample: false)
        }
    }
}

final class LeaderboardTests: XCTestCase {
    let time = Clock()
    let board = FakeBoard()

    @MainActor func makeApp() -> AppModel {
        let time = self.time
        return AppModel(store: FileStore(url: nil), leaderboard: board, now: { time.now })
    }

    @MainActor func solveDaily(_ app: AppModel, seconds: Double) async -> PuzzleSession {
        let s = PuzzleSession(route: .daily(app.today), app: app)!
        s.setVisible(true)
        time.now += seconds
        for cell in s.puzzle.solutionCells { s.act(.place(cell)) }
        await s.submitTask?.value
        return s
    }

    func testTodayIsTheUTCDate() {
        // 23:30 UTC on Oct 22 is already Oct 23 in Tokyo and still Oct 22 in LA
        let t = Date(timeIntervalSince1970: 1_792_711_800)
        XCTAssertEqual(Daily.todayKey(t), "2026-10-22")
        XCTAssertEqual(Daily.nextReset(after: t).timeIntervalSince(t), 30 * 60)
    }

    func testPlausibility() {
        XCTAssertFalse(Daily.isPlausible(timeMs: 4_000, size: 7))
        XCTAssertTrue(Daily.isPlausible(timeMs: 5_600, size: 7))
    }

    func testSolvedDailyIsPosted() async { await _testSolvedDailyIsPosted() }
    @MainActor func _testSolvedDailyIsPosted() async {
        let app = makeApp()
        let s = await solveDaily(app, seconds: 95)
        XCTAssertEqual(board.posted.map(\.timeMs), [95_000])
        XCTAssertEqual(app.store.daily(app.today)?.submitted, true)
        XCTAssertEqual(s.result?.rank, 1)
        XCTAssertNil(s.submitNote)
    }

    func testTooFastIsNotPosted() async { await _testTooFastIsNotPosted() }
    @MainActor func _testTooFastIsNotPosted() async {
        let app = makeApp()
        let s = await solveDaily(app, seconds: 2)
        XCTAssertTrue(board.posted.isEmpty)
        XCTAssertNotNil(s.submitNote)
        let retried = await app.submitPendingDaily()
        XCTAssertFalse(retried)
    }

    func testOfflineTimeIsPostedLaterTheSameDay() async { await _testOfflineTimeIsPostedLaterTheSameDay() }
    @MainActor func _testOfflineTimeIsPostedLaterTheSameDay() async {
        let app = makeApp()
        board.mode = .offline
        let s = await solveDaily(app, seconds: 120)
        XCTAssertEqual(app.store.daily(app.today)?.submitted, false)
        XCTAssertEqual(s.submitNote, "Your time is saved and will post when you're back online.")
        board.mode = .ok
        let lb = LeaderboardModel(app: app)
        await lb.load() // opening the leaderboard retries
        XCTAssertEqual(board.posted.map(\.timeMs), [120_000])
        XCTAssertEqual(app.store.daily(app.today)?.submitted, true)
    }

    func testSignedOutTimeIsNotPostedToTheNextDay() async { await _testSignedOutTimeIsNotPostedToTheNextDay() }
    @MainActor func _testSignedOutTimeIsNotPostedToTheNextDay() async {
        let app = makeApp()
        board.mode = .signedOut
        let s = await solveDaily(app, seconds: 200)
        XCTAssertEqual(s.submitNote, "Sign in to Game Center to post your time. It's saved until then.")
        board.mode = .ok
        time.now += 86_400 // the next UTC day
        let retried = await app.submitPendingDaily()
        XCTAssertFalse(retried)
        XCTAssertTrue(board.posted.isEmpty)
    }

    func testSignedOutBoardState() async { await _testSignedOutBoardState() }
    @MainActor func _testSignedOutBoardState() async {
        let app = makeApp()
        board.mode = .signedOut
        let lb = LeaderboardModel(app: app)
        await lb.load()
        XCTAssertEqual(lb.state, .loaded(.signedOut))
        XCTAssertTrue(lb.visibleRows.isEmpty)
    }
}
