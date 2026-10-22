import XCTest
@testable import CatLogicKit

final class GameTests: XCTestCase {
    let p = try! Daily.puzzle(for: "2026-10-20")
    func right(_ r: Int) -> Int { r * p.size + p.solution[r] }
    func wrong(_ r: Int) -> Int { r * p.size + (p.solution[r] + 2) % p.size }

    func testTapCycles() {
        var g = Game(puzzle: p)
        g.apply(.tap(right(0)))
        XCTAssertEqual(g.cells[right(0)], .mark)
        g.apply(.tap(right(0)))
        XCTAssertEqual(g.cells[right(0)], .cat)
        g.apply(.tap(right(0)))
        XCTAssertEqual(g.cells[right(0)], .empty)
    }

    func testWrongCatCostsALifeAndLeavesAMark() {
        let g = Game(puzzle: p).applying(.place(wrong(0)))
        XCTAssertEqual(g.lives, 2)
        XCTAssertEqual(g.cells[wrong(0)], .mark)
        XCTAssertEqual(g.lastMistake, wrong(0))
    }

    func testThreeMistakesFailAndFreeze() {
        var g = Game(puzzle: p)
        for r in 0..<3 { g.apply(.place(wrong(r))) }
        XCTAssertEqual(g.status, .failed)
        XCTAssertEqual(g.applying(.place(right(0))), g)
        XCTAssertEqual(g.applying(.restart).lives, 3)
    }

    func testEveryAnswerCatSolves() {
        var g = Game(puzzle: p)
        for r in 0..<p.size { g.apply(.place(right(r))) }
        XCTAssertEqual(g.status, .solved)
    }

    func testUndoKeepsLivesLost() {
        var g = Game(puzzle: p).applying(.place(wrong(0)))
        g.apply(.tap(right(1)))
        g.apply(.undo)
        XCTAssertEqual(g.cells[right(1)], .empty)
        XCTAssertEqual(g.lives, 2)
    }

    func testHintPointsAtAnUnplacedAnswer() {
        let g = Game(puzzle: p).applying(.place(right(0))).applying(.hint)
        let h = try! XCTUnwrap(g.hinted)
        XCTAssertNotEqual(h, right(0))
        XCTAssertEqual(h, right(h / p.size))
    }
}
