import Foundation

// The daily puzzle is a pure function of the player's local date (mirrors
// engine/daily.ts), so it works offline and a server can rebuild it.
public enum Daily {
    public static let seedPrefix = "daily-v\(Generator.generatorVersion)"

    // Index by weekday, Sunday = 0
    static let byWeekday: [(size: Int, min: Difficulty, max: Difficulty)] = [
        (9, .hard, .hard), // Sun
        (6, .easy, .medium), // Mon
        (6, .medium, .medium), // Tue
        (7, .medium, .medium), // Wed
        (7, .medium, .hard), // Thu
        (8, .medium, .medium), // Fri
        (8, .medium, .hard), // Sat
    ]

    public static func isDateKey(_ key: String) -> Bool {
        key.range(of: #"^\d{4}-\d{2}-\d{2}$"#, options: .regularExpression) != nil
    }

    public static func localDateKey(_ date: Date = Date(), calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year!, c.month!, c.day!)
    }

    // Gregorian weekday without Calendar, so every platform agrees (Sun = 0)
    static func weekday(_ y: Int, _ m: Int, _ d: Int) -> Int {
        let t = [0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4]
        let yy = m < 3 ? y - 1 : y
        return (yy + yy / 4 - yy / 100 + yy / 400 + t[m - 1] + d) % 7
    }

    public static func puzzle(for dateKey: String) throws -> SolvedPuzzle {
        guard isDateKey(dateKey) else { throw Generator.Failure(description: "bad date \(dateKey)") }
        let parts = dateKey.split(separator: "-").map { Int($0)! }
        let spec = byWeekday[weekday(parts[0], parts[1], parts[2])]
        return try Generator.generate(seed: "\(seedPrefix):\(dateKey)", size: spec.size, min: spec.min, max: spec.max)
    }

    // The day before a YYYY-MM-DD key, without time zones
    public static func previousDay(_ key: String) -> String {
        var p = key.split(separator: "-").map { Int($0)! }
        p[2] -= 1
        if p[2] == 0 {
            p[1] -= 1
            if p[1] == 0 {
                p[1] = 12
                p[0] -= 1
            }
            let leap = (p[0] % 4 == 0 && p[0] % 100 != 0) || p[0] % 400 == 0
            p[2] = [31, leap ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][p[1] - 1]
        }
        return String(format: "%04d-%02d-%02d", p[0], p[1], p[2])
    }
}
