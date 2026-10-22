import Foundation
import XCTest
@testable import CatLogicKit

// Linux XCTest can't run @MainActor tests directly, so each test is a plain
// wrapper that enters the main actor (tests run on the main thread).
final class Clock: @unchecked Sendable {
    var now = Date(timeIntervalSince1970: 1_792_000_000) // a fixed day
}

final class ModelTests: XCTestCase {
    let time = Clock()
    var clock: Date {
        get { time.now }
        set { time.now = newValue }
    }

    @MainActor func makeApp() -> AppModel {
        let time = self.time
        return AppModel(store: FileStore(url: nil), leaderboard: SampleLeaderboard(), now: { time.now })
    }

    @MainActor func solve(_ s: PuzzleSession) {
        for cell in s.puzzle.solutionCells { s.act(.place(cell)) }
    }

    func testTimerOnlyRunsWhileVisibleAndNoSheet() { MainActor.assumeIsolated { _testTimerOnlyRunsWhileVisibleAndNoSheet() } }
    @MainActor func _testTimerOnlyRunsWhileVisibleAndNoSheet() {
        let app = makeApp()
        let s = PuzzleSession(route: .level(1), app: app)!
        s.setVisible(true)
        clock += 10
        s.setSheetOpen(true)
        clock += 100 // not counted
        s.setSheetOpen(false)
        clock += 5
        s.setVisible(false)
        clock += 50 // not counted
        XCTAssertEqual(s.elapsed(), 15_000)
    }

    func testProgressIsSavedAndRestored() { MainActor.assumeIsolated { _testProgressIsSavedAndRestored() } }
    @MainActor func _testProgressIsSavedAndRestored() {
        let app = makeApp()
        let s = PuzzleSession(route: .level(3), app: app)!
        s.setVisible(true)
        clock += 7
        s.act(.tap(0))
        let again = PuzzleSession(route: .level(3), app: app)!
        XCTAssertEqual(again.game.cells[0], .mark)
        XCTAssertEqual(again.elapsed(), 7_000)
    }

    func testSolvingALevelRecordsBestTime() { MainActor.assumeIsolated { _testSolvingALevelRecordsBestTime() } }
    @MainActor func _testSolvingALevelRecordsBestTime() {
        let app = makeApp()
        let s = PuzzleSession(route: .level(1), app: app)!
        s.setVisible(true)
        clock += 42
        solve(s)
        XCTAssertEqual(s.game.status, .solved)
        XCTAssertEqual(s.result?.bestMs, 42_000)
        XCTAssertEqual(app.store.levels[1]?.bestMs, 42_000)
        XCTAssertNil(app.store.attempt(.level, "1"))
        XCTAssertEqual(s.feedback, .solved)
        XCTAssertEqual(HomeModel(app: app).next, 2)
    }

    func testDailyIsOnlyToday() { MainActor.assumeIsolated { _testDailyIsOnlyToday() } }
    @MainActor func _testDailyIsOnlyToday() {
        let app = makeApp()
        XCTAssertNil(PuzzleSession(route: .daily("2020-01-01"), app: app))
        XCTAssertNil(PuzzleSession(route: .level(999), app: app))
        XCTAssertNotNil(PuzzleSession(route: .daily(app.today), app: app))
    }

    func testSolvingTheDailyRecordsItEarnsAHintAndLocksIt() async { await _testSolvingTheDailyRecordsItEarnsAHintAndLocksIt() }
    @MainActor func _testSolvingTheDailyRecordsItEarnsAHintAndLocksIt() async {
        let app = makeApp()
        let s = PuzzleSession(route: .daily(app.today), app: app)!
        s.setVisible(true)
        clock += 90
        solve(s)
        XCTAssertEqual(app.store.daily(app.today)?.timeMs, 90_000)
        XCTAssertEqual(s.hints, FileStore.startHints + 1)
        XCTAssertEqual(HomeModel(app: app).streak, 1)
        let reopened = PuzzleSession(route: .daily(app.today), app: app)!
        XCTAssertEqual(reopened.solvedBefore?.timeMs, 90_000)
        XCTAssertEqual(reopened.game.status, .solved)
        let board = LeaderboardModel(app: app)
        await board.load()
        XCTAssertTrue(board.visibleRows.contains { $0.isMe && $0.timeMs == 90_000 })
    }

    func testMistakesFailAndDailyRetryKeepsTheClock() { MainActor.assumeIsolated { _testMistakesFailAndDailyRetryKeepsTheClock() } }
    @MainActor func _testMistakesFailAndDailyRetryKeepsTheClock() {
        let app = makeApp()
        let s = PuzzleSession(route: .daily(app.today), app: app)!
        s.setVisible(true)
        let wrong = s.puzzle.regions.indices.filter { !s.puzzle.isAnswer($0) }
        for cell in wrong.prefix(3) { s.act(.place(cell)) }
        XCTAssertEqual(s.game.status, .failed)
        XCTAssertEqual(s.feedback, .mistake)
        clock += 30
        s.restart()
        clock += 5
        XCTAssertEqual(s.game.lives, 3)
        XCTAssertEqual(s.elapsed(), 5_000) // the 30 s while failed don't count; the clock wasn't reset
    }

    func testHintsRunOut() { MainActor.assumeIsolated { _testHintsRunOut() } }
    @MainActor func _testHintsRunOut() {
        let app = makeApp()
        let s = PuzzleSession(route: .level(5), app: app)!
        for _ in 0..<FileStore.startHints { s.spendHint() }
        XCTAssertEqual(s.hints, 0)
        XCTAssertNotNil(s.game.hinted)
        s.spendHint()
        XCTAssertEqual(s.hints, 0)
    }

    func testSettingsPersistThroughTheStore() { MainActor.assumeIsolated { _testSettingsPersistThroughTheStore() } }
    @MainActor func _testSettingsPersistThroughTheStore() {
        let app = makeApp()
        app.settings.regionPatterns = true
        XCTAssertTrue(app.store.settings.regionPatterns)
    }

    func testFileStoreWritesAndReadsBack() throws { try MainActor.assumeIsolated { try _testFileStoreWritesAndReadsBack() } }
    @MainActor func _testFileStoreWritesAndReadsBack() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("cl-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }
        let a = FileStore(url: url)
        _ = a.recordLevelSolve(4, ms: 1234)
        a.setFlag("seenTutorial", true)
        let b = FileStore(url: url)
        XCTAssertEqual(b.levels[4]?.bestMs, 1234)
        XCTAssertTrue(b.flag("seenTutorial"))
    }
}
