// Mirrors engine/generator.ts. Changing anything here changes every daily
// puzzle: bump generatorVersion (and the TypeScript) together, never apart.
public enum Generator {
    public static let generatorVersion = 1

    public struct Failure: Error, CustomStringConvertible {
        public let description: String
    }

    static func randomSolution(_ rng: inout Rng, _ size: Int) -> [Int] {
        var used = [Bool](repeating: false, count: size)
        var pick: [Int] = []
        func step(_ r: Int) -> Bool {
            if r == size { return true }
            for c in rng.shuffled(Array(0..<size)) {
                if used[c] || (r > 0 && abs(pick[r - 1] - c) <= 1) { continue }
                used[c] = true
                pick.append(c)
                if step(r + 1) { return true }
                pick.removeLast()
                used[c] = false
            }
            return false
        }
        _ = step(0)
        return pick
    }

    static func growRegions(_ rng: inout Rng, _ size: Int, _ solution: [Int]) -> [Int] {
        var regions = [Int](repeating: -1, count: size * size)
        var frontier: [Int] = []
        for (r, c) in solution.enumerated() {
            let cell = r * size + c
            regions[cell] = r
            frontier.append(cell)
        }
        var left = size * size - size
        while left > 0 {
            let i = rng.int(frontier.count)
            let from = frontier[i]
            let open = Rules.orthogonal(size, from).filter { regions[$0] == -1 }
            if open.isEmpty {
                frontier.remove(at: i)
                continue
            }
            let to = open[rng.int(open.count)]
            regions[to] = regions[from]
            frontier.append(to)
            left -= 1
        }
        return regions
    }

    // Kill a second solution by moving one of its cats into a neighbouring
    // region. The real answer's cats never move, so it stays valid.
    static func breakAlternative(_ rng: inout Rng, _ p: inout Puzzle, real: [Int], alt: [Int]) -> Bool {
        let size = p.size
        let realCells = Set(real.enumerated().map { $0.offset * size + $0.element })
        let altCells = rng.shuffled(alt.enumerated().map { $0.offset * size + $0.element }.filter { !realCells.contains($0) })
        for cell in altCells {
            let from = p.regions[cell]
            for n in rng.shuffled(Rules.orthogonal(size, cell)) {
                let to = p.regions[n]
                if to == from { continue }
                p.regions[cell] = to
                if Rules.regionsConnected(p) { return true }
                p.regions[cell] = from
            }
        }
        return false
    }

    public static func generate(_ rng: inout Rng, size: Int, maxAttempts: Int = 200) throws -> SolvedPuzzle {
        guard size >= minSize, size <= maxSize else { throw Failure(description: "size \(size) out of range") }
        for _ in 0..<maxAttempts {
            let solution = randomSolution(&rng, size)
            var puzzle = Puzzle(size: size, regions: growRegions(&rng, size, solution))
            for _ in 0..<(size * size) {
                let found = Solver.findSolutions(puzzle, limit: 2)
                if found.count == 1 {
                    return SolvedPuzzle(puzzle: puzzle, solution: solution, difficulty: Grader.grade(puzzle))
                }
                guard let alt = found.first(where: { $0 != solution }),
                      breakAlternative(&rng, &puzzle, real: solution, alt: alt) else { break }
            }
        }
        throw Failure(description: "no unique \(size)x\(size) puzzle after \(maxAttempts) attempts")
    }

    public static func generate(seed: String, size: Int, min: Difficulty, max: Difficulty, maxTries: Int = 60) throws -> SolvedPuzzle {
        var rng = Rng(seed: seed)
        var last: SolvedPuzzle?
        for _ in 0..<maxTries {
            let p = try generate(&rng, size: size)
            last = p
            if p.difficulty >= min && p.difficulty <= max { return p }
        }
        return last!
    }
}
