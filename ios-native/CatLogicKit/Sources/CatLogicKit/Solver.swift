public enum Solver {
    // Backtracking one row at a time, columns in order 0..n-1 (same as
    // solver.ts, so "the first other solution" matches). Stops at `limit`.
    public static func findSolutions(_ p: Puzzle, limit: Int = 2) -> [[Int]] {
        let size = p.size
        var found: [[Int]] = []
        var cols = [Bool](repeating: false, count: size)
        var regs = [Bool](repeating: false, count: size)
        var pick: [Int] = []

        func step(_ r: Int) {
            if found.count >= limit { return }
            if r == size {
                found.append(pick)
                return
            }
            for c in 0..<size {
                if cols[c] { continue }
                if r > 0, abs(pick[r - 1] - c) <= 1 { continue }
                let g = p.regions[r * size + c]
                if regs[g] { continue }
                cols[c] = true
                regs[g] = true
                pick.append(c)
                step(r + 1)
                pick.removeLast()
                cols[c] = false
                regs[g] = false
                if found.count >= limit { return }
            }
        }
        step(0)
        return found
    }

    public static func countSolutions(_ p: Puzzle, limit: Int = 2) -> Int {
        findSolutions(p, limit: limit).count
    }
}
