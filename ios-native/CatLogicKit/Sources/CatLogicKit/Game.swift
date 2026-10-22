// Game rules for one board (mirrors src/game/game.ts).

public enum CellState: Int, Codable, Sendable {
    case empty = 0, mark = 1, cat = 2
}

public struct Move: Codable, Equatable, Sendable {
    public var cell: Int
    public var from: CellState
    public var to: CellState
}

public enum GameStatus: String, Codable, Sendable {
    case playing, solved, failed
}

public enum GameAction: Sendable {
    case tap(Int) // empty -> mark -> cat -> empty
    case place(Int) // double tap
    case clear(Int) // long press
    case undo, restart, hint
}

public struct Game: Equatable, Sendable {
    public static let startLives = 3

    public let puzzle: SolvedPuzzle
    public var cells: [CellState]
    public var lives = Game.startLives
    public var mistakes = 0
    public var history: [Move] = []
    public var status = GameStatus.playing
    public var lastMistake: Int?
    public var hinted: Int?

    public init(puzzle: SolvedPuzzle) {
        self.puzzle = puzzle
        cells = Array(repeating: .empty, count: puzzle.size * puzzle.size)
    }

    public var catCount: Int { cells.filter { $0 == .cat }.count }

    public func applying(_ action: GameAction) -> Game {
        var g = self
        g.apply(action)
        return g
    }

    public mutating func apply(_ action: GameAction) {
        if case .restart = action {
            self = Game(puzzle: puzzle)
            return
        }
        guard status == .playing else { return }
        switch action {
        case .tap(let cell):
            switch cells[cell] {
            case .empty: set(cell, .mark)
            case .mark: placeCat(cell)
            case .cat: set(cell, .empty)
            }
        case .place(let cell):
            if cells[cell] != .cat { placeCat(cell) }
        case .clear(let cell):
            set(cell, .empty)
        case .undo:
            guard let last = history.popLast() else { return }
            cells[last.cell] = last.from
            lastMistake = nil
        case .hint:
            hinted = nextHint()
        case .restart:
            break
        }
    }

    private mutating func set(_ cell: Int, _ to: CellState) {
        let from = cells[cell]
        guard from != to else { return }
        cells[cell] = to
        history.append(Move(cell: cell, from: from, to: to))
        lastMistake = nil
        if hinted == cell { hinted = nil }
    }

    // A cat on a cell that is not in the (unique) answer costs a life. The cat
    // does not stay: the cell is marked instead, since it can never hold one.
    private mutating func placeCat(_ cell: Int) {
        guard puzzle.isAnswer(cell) else {
            cells[cell] = .mark
            lives -= 1
            mistakes += 1
            lastMistake = cell
            if lives <= 0 { status = .failed }
            return
        }
        set(cell, .cat)
        if catCount == puzzle.size {
            status = .solved
            hinted = nil
        }
    }

    // The answer cell in the most squeezed row, column or region.
    public func nextHint() -> Int? {
        let n = puzzle.size
        var best: Int?
        var bestOpen = Int.max
        for (r, c) in puzzle.solution.enumerated() {
            let cell = r * n + c
            if cells[cell] == .cat { continue }
            func open(_ pred: (Int) -> Bool) -> Int {
                cells.indices.reduce(0) { pred($1) && cells[$1] == .empty ? $0 + 1 : $0 }
            }
            let tightest = Swift.min(
                open { $0 / n == r },
                open { $0 % n == c },
                open { puzzle.regions[$0] == puzzle.regions[cell] }
            )
            if tightest < bestOpen {
                bestOpen = tightest
                best = cell
            }
        }
        return best
    }
}
