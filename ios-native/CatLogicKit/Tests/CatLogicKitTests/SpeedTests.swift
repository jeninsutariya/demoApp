import Foundation
import XCTest
@testable import CatLogicKit

// The daily is generated on the phone when it opens. Run in release to see
// real numbers: swift test -c release --filter SpeedTests
final class SpeedTests: XCTestCase {
    func testWeekOfDailies() throws {
        var worst = 0.0
        for day in 19...25 {
            let start = Date()
            _ = try Daily.puzzle(for: "2026-10-\(day)")
            worst = max(worst, Date().timeIntervalSince(start))
        }
        print("slowest daily of the week: \(Int(worst * 1000)) ms")
    }
}
