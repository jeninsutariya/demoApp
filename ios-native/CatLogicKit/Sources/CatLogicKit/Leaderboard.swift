public struct LeaderboardRow: Equatable, Sendable, Identifiable {
    public var rank: Int
    public var name: String
    public var timeMs: Int
    public var isMe: Bool
    public var id: String { "\(rank)-\(name)" }
}

public enum LeaderboardResult: Equatable, Sendable {
    case ok(rows: [LeaderboardRow], sample: Bool)
    case offline
    case error(String)
}

// The daily leaderboard. /replica-backend replaces the sample with the real
// one (Game Center's daily leaderboards, or the Supabase plan).
public protocol LeaderboardService: Sendable {
    func submitDaily(date: String, cats: [Int], timeMs: Int, mistakes: Int) async throws -> (rank: Int, total: Int)?
    func daily(date: String, myTimeMs: Int?) async -> LeaderboardResult
    func deleteMe() async throws
}

// SAMPLE until the backend exists. Other players are generated from the date
// (same numbers as src/data/leaderboard.ts) and the screen says so.
public struct SampleLeaderboard: LeaderboardService {
    static let players = 40
    public init() {}

    static func times(_ date: String) -> [Int] {
        var rng = Rng(seed: "sample-board:\(date)")
        return (0..<players).map { _ in Int((60_000 + rng.next() * rng.next() * 600_000).rounded()) }.sorted()
    }

    public func submitDaily(date: String, cats: [Int], timeMs: Int, mistakes: Int) async throws -> (rank: Int, total: Int)? {
        let times = Self.times(date)
        return (times.filter { $0 < timeMs }.count + 1, times.count + 1)
    }

    public func daily(date: String, myTimeMs: Int?) async -> LeaderboardResult {
        var rows = Self.times(date).enumerated().map {
            LeaderboardRow(rank: $0.offset + 1, name: "Sample player \($0.offset + 1)", timeMs: $0.element, isMe: false)
        }
        if let myTimeMs {
            rows.append(LeaderboardRow(rank: 0, name: "You", timeMs: myTimeMs, isMe: true))
            rows.sort { $0.timeMs < $1.timeMs }
            for i in rows.indices { rows[i].rank = i + 1 }
        }
        return .ok(rows: rows, sample: true)
    }

    public func deleteMe() async throws {}
}
