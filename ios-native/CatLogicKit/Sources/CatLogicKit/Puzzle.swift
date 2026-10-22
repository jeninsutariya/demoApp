// An N x N board split into N regions. Cells are row-major indexes
// (r * size + c). The answer has exactly one cat per row, column and region,
// and no two cats touch, diagonals included.

public enum Difficulty: Int, Codable, Sendable, Comparable, CaseIterable {
    case easy = 1, medium, hard, expert

    public static func < (a: Difficulty, b: Difficulty) -> Bool { a.rawValue < b.rawValue }

    public var label: String {
        switch self {
        case .easy: "Easy"
        case .medium: "Medium"
        case .hard: "Hard"
        case .expert: "Expert"
        }
    }
}

public struct Puzzle: Equatable, Codable, Sendable {
    public var size: Int
    public var regions: [Int] // region 0..size-1 for every cell

    public init(size: Int, regions: [Int]) {
        self.size = size
        self.regions = regions
    }
}

public struct SolvedPuzzle: Equatable, Codable, Sendable {
    public var puzzle: Puzzle
    public var solution: [Int] // solution[r] = column of the cat in row r
    public var difficulty: Difficulty

    public var size: Int { puzzle.size }
    public var regions: [Int] { puzzle.regions }
    public var solutionCells: [Int] { solution.enumerated().map { $0.offset * size + $0.element } }

    public init(puzzle: Puzzle, solution: [Int], difficulty: Difficulty) {
        self.puzzle = puzzle
        self.solution = solution
        self.difficulty = difficulty
    }

    public func isAnswer(_ cell: Int) -> Bool { solution[cell / size] == cell % size }
}

public let minSize = 5
public let maxSize = 10
