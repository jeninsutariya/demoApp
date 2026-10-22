import Foundation
import XCTest
@testable import CatLogicKit

final class UnlockTests: XCTestCase {
    func testFreeLevelsThenLocked() { MainActor.assumeIsolated { _testFreeLevelsThenLocked() } }
    @MainActor func _testFreeLevelsThenLocked() {
        let app = AppModel(store: FileStore(url: nil), leaderboard: SampleLeaderboard())
        XCTAssertTrue(app.isPlayable(level: 60))
        XCTAssertFalse(app.isPlayable(level: 61))
        XCTAssertNotNil(PuzzleSession(route: .level(60), app: app))
        XCTAssertNil(PuzzleSession(route: .level(61), app: app))
        XCTAssertTrue(PuzzleSession(route: .level(60), app: app)!.nextLevelIsLocked)
        XCTAssertFalse(PuzzleSession(route: .level(59), app: app)!.nextLevelIsLocked)
    }

    func testUnlockOpensEverythingAndIsRemembered() { MainActor.assumeIsolated { _testUnlockOpensEverythingAndIsRemembered() } }
    @MainActor func _testUnlockOpensEverythingAndIsRemembered() {
        let store = FileStore(url: nil)
        let app = AppModel(store: store, leaderboard: SampleLeaderboard())
        app.setAllLevelsUnlocked(true)
        XCTAssertTrue(app.isPlayable(level: LevelPack.count))
        XCTAssertFalse(app.isPlayable(level: LevelPack.count + 1))
        XCTAssertNotNil(PuzzleSession(route: .level(300), app: app))
        // a fresh app on the same store (offline relaunch) stays unlocked
        XCTAssertTrue(AppModel(store: store, leaderboard: SampleLeaderboard()).allLevelsUnlocked)
        // a refund turns it off again
        app.setAllLevelsUnlocked(false)
        XCTAssertFalse(app.isPlayable(level: 61))
    }

    func testHomeShowsWhenTheNextLevelIsLocked() { MainActor.assumeIsolated { _testHomeShowsWhenTheNextLevelIsLocked() } }
    @MainActor func _testHomeShowsWhenTheNextLevelIsLocked() {
        let app = AppModel(store: FileStore(url: nil), leaderboard: SampleLeaderboard())
        app.store.recordLevelSolve(60, ms: 1000)
        let home = HomeModel(app: app)
        XCTAssertEqual(home.next, 61)
        XCTAssertTrue(home.nextIsLocked)
    }
}
