import Foundation

public enum PuzzleKind: String, Codable, Sendable {
    case level, daily
}

public struct Settings: Codable, Equatable, Sendable {
    public var haptics = true
    public var sound = true
    public var hideTimer = false
    public var regionPatterns = false
    public init() {}
}

public struct SavedAttempt: Codable, Equatable, Sendable {
    public var kind: PuzzleKind
    public var key: String // level number or YYYY-MM-DD
    public var cells: [CellState]
    public var history: [Move]
    public var lives: Int
    public var mistakes: Int
    public var elapsedMs: Int
}

public struct LevelRecord: Codable, Equatable, Sendable {
    public var bestMs: Int
    public var solves: Int
}

public struct DailyRecord: Codable, Equatable, Sendable {
    public enum Status: String, Codable, Sendable { case solved, failed }
    public var date: String
    public var status: Status
    public var timeMs: Int
    public var mistakes: Int
    public var submitted: Bool
}

// Everything the app keeps on the device. Same calls as GameRepo in
// src/data/types.ts. This version writes one small JSON file; a SwiftData or
// SQLite version can replace it behind the same protocol.
public protocol GameStore: AnyObject {
    var settings: Settings { get set }
    func flag(_ name: String) -> Bool
    func setFlag(_ name: String, _ on: Bool)

    func attempt(_ kind: PuzzleKind, _ key: String) -> SavedAttempt?
    func saveAttempt(_ a: SavedAttempt)
    func clearAttempt(_ kind: PuzzleKind, _ key: String)

    var levels: [Int: LevelRecord] { get }
    @discardableResult func recordLevelSolve(_ level: Int, ms: Int) -> LevelRecord

    func daily(_ date: String) -> DailyRecord?
    func recordDaily(_ rec: DailyRecord)
    func dailyStreak(today: String) -> Int

    var hints: Int { get }
    @discardableResult func addHints(_ n: Int) -> Int
}

public final class FileStore: GameStore {
    public static let startHints = 3

    struct SaveData: Codable {
        var settings = Settings()
        var flags: [String: Bool] = [:]
        var attempts: [String: SavedAttempt] = [:]
        var levels: [Int: LevelRecord] = [:]
        var dailies: [String: DailyRecord] = [:]
        var hints = FileStore.startHints
    }

    private let url: URL?
    private var data: SaveData

    // url nil keeps everything in memory (tests and previews)
    public init(url: URL?) {
        self.url = url
        if let url, let raw = try? Data(contentsOf: url), let saved = try? JSONDecoder().decode(SaveData.self, from: raw) {
            data = saved
        } else {
            data = SaveData()
        }
    }

    public static func standard() -> FileStore {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return FileStore(url: dir.appendingPathComponent("progress.json"))
    }

    private func save() {
        guard let url, let raw = try? JSONEncoder().encode(data) else { return }
        try? raw.write(to: url, options: .atomic)
    }

    private static func key(_ kind: PuzzleKind, _ key: String) -> String { "\(kind.rawValue):\(key)" }

    public var settings: Settings {
        get { data.settings }
        set { data.settings = newValue; save() }
    }

    public func flag(_ name: String) -> Bool { data.flags[name] ?? false }
    public func setFlag(_ name: String, _ on: Bool) { data.flags[name] = on; save() }

    public func attempt(_ kind: PuzzleKind, _ key: String) -> SavedAttempt? { data.attempts[Self.key(kind, key)] }
    public func saveAttempt(_ a: SavedAttempt) { data.attempts[Self.key(a.kind, a.key)] = a; save() }
    public func clearAttempt(_ kind: PuzzleKind, _ key: String) { data.attempts[Self.key(kind, key)] = nil; save() }

    public var levels: [Int: LevelRecord] { data.levels }
    public func recordLevelSolve(_ level: Int, ms: Int) -> LevelRecord {
        let was = data.levels[level]
        let rec = LevelRecord(bestMs: was.map { min($0.bestMs, ms) } ?? ms, solves: (was?.solves ?? 0) + 1)
        data.levels[level] = rec
        save()
        return rec
    }

    public func daily(_ date: String) -> DailyRecord? { data.dailies[date] }
    public func recordDaily(_ rec: DailyRecord) { data.dailies[rec.date] = rec; save() }

    // Today counts if solved; an unsolved today doesn't break yesterday's run.
    public func dailyStreak(today: String) -> Int {
        var streak = data.dailies[today]?.status == .solved ? 1 : 0
        var day = Daily.previousDay(today)
        while data.dailies[day]?.status == .solved {
            streak += 1
            day = Daily.previousDay(day)
        }
        return streak
    }

    public var hints: Int { data.hints }
    public func addHints(_ n: Int) -> Int {
        data.hints = max(0, data.hints + n)
        save()
        return data.hints
    }
}
