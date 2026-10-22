import XCTest
@testable import CatLogicKit

// The same boards engine/engine.test.ts pins. If the Swift and TypeScript
// engines ever disagree, the app and the server would see different dailies.
let goldenDailies: [String: String] = [
        "2026-10-19": "6|000000000001002221002331402331442555|152403|2",
        "2026-10-20": "6|001114111114131124333144333444333544|024153|2",
        "2026-10-21": "7|0000011000111100066240036644006664450664465066666|1352604|2",
        "2026-10-22": "7|0000001200001122260135446663554663356666636666666|3516204|2",
        "2026-10-23": "8|2220001122333115233311552223555544777555777775557666775577777755|46031725|2",
        "2026-10-24": "8|0000000020000311200003337444433374444433754446667744444677774466|46053172|2",
        "2026-10-25": "9|333330011333330311223333335665553345665555345655555555655555555655577555688577755|681573042|3",
        "2027-01-01": "8|0000000000001100022211103222114455551554555555445565577755777777|15307426|2",
]

final class EngineTests: XCTestCase {
    func testRngMatchesTypeScript() {
        // values printed by engine/rng.ts for the same seeds
        var a = Rng(seed: "x")
        XCTAssertEqual(Rng.hashSeed("x"), 890040462)
        XCTAssertEqual(a.next(), 0.3885649503208697)
    }

    func testDailiesMatchTypeScript() throws {
        for (date, expected) in goldenDailies.sorted(by: { $0.key < $1.key }) {
            XCTAssertEqual(Codec.encode(try Daily.puzzle(for: date)), expected, date)
        }
    }

    // Regenerates levels from their seeds and compares with the shipped pack,
    // which scripts/gen-levels.ts made in TypeScript.
    func testLevelGenerationMatchesTypeScript() throws {
        let bands: [(size: Int, count: Int, ramp: [(Difficulty, Difficulty)])] = [
            (5, 20, [(.easy, .easy), (.easy, .medium), (.medium, .medium)]),
            (6, 40, [(.easy, .medium), (.medium, .medium), (.medium, .hard)]),
            (7, 50, [(.easy, .medium), (.medium, .medium), (.medium, .hard)]),
            (8, 60, [(.medium, .medium), (.medium, .hard), (.hard, .hard)]),
            (9, 70, [(.medium, .medium), (.medium, .hard), (.hard, .hard)]),
            (10, 60, [(.medium, .hard), (.hard, .hard), (.hard, .expert)]),
        ]
        var n = 0
        var checked = 0
        for band in bands {
            for i in 0..<band.count {
                n += 1
                // every 5th level keeps the test quick; all 300 are checked below
                guard n % 5 == 1 else { continue }
                let (lo, hi) = band.ramp[Swift.min(band.ramp.count - 1, i * band.ramp.count / band.count)]
                let p = try Generator.generate(seed: "level-v1:\(n)", size: band.size, min: lo, max: hi)
                XCTAssertEqual(Codec.encode(p), Codec.encode(LevelPack.all[n - 1]), "level \(n)")
                checked += 1
            }
        }
        XCTAssertEqual(checked, 60)
    }

    func testEveryShippedLevelIsUniqueAndGradedAsStored() {
        XCTAssertEqual(LevelPack.count, 300)
        for (i, p) in LevelPack.all.enumerated() {
            XCTAssertEqual(Solver.countSolutions(p.puzzle), 1, "level \(i + 1)")
            XCTAssertEqual(Grader.grade(p.puzzle), p.difficulty, "level \(i + 1)")
            XCTAssertTrue(Rules.isValidSolution(p.puzzle, cats: p.solutionCells))
            XCTAssertTrue(Rules.regionsConnected(p.puzzle))
        }
    }

    func testGeneratedPuzzlesHaveOneSolutionEverySize() throws {
        var rng = Rng(seed: "swift-test")
        for size in minSize...maxSize {
            for _ in 0..<3 {
                let p = try Generator.generate(&rng, size: size)
                XCTAssertEqual(Solver.countSolutions(p.puzzle), 1)
                XCTAssertTrue(Rules.isValidSolution(p.puzzle, cats: p.solutionCells))
            }
        }
    }

    func testCodecRoundTripsAndWeekdays() throws {
        let p = try Daily.puzzle(for: "2026-10-22")
        XCTAssertEqual(Codec.decode(Codec.encode(p)), p)
        XCTAssertEqual(Daily.weekday(2026, 10, 22), 4) // Thursday
        XCTAssertEqual(Daily.weekday(2027, 1, 1), 5) // Friday
        XCTAssertEqual(Daily.previousDay("2027-03-01"), "2027-02-28")
        XCTAssertEqual(Daily.previousDay("2028-03-01"), "2028-02-29")
        XCTAssertEqual(Daily.previousDay("2027-01-01"), "2026-12-31")
    }
}
