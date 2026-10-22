// Solves the way a person would, with no guessing, and returns the hardest
// technique it needed (mirrors engine/grader.ts step for step, because the
// generator keeps or rejects boards by this grade):
// easy    a row, column or region has one place left
// medium  a cell would empty some row, column or region (one-step lookahead)
// hard    k regions squeezed into k rows or columns (and the reverse), k <= 4
// expert  none of the above finish it; the solution is still unique
public enum Grader {
    private struct State {
        var cand: [Bool]
        var cats: Set<Int>
    }

    public static func grade(_ p: Puzzle) -> Difficulty {
        var s = State(cand: [Bool](repeating: true, count: p.size * p.size), cats: [])
        let all = units(p)
        var hardest = Difficulty.easy
        while s.cats.count < p.size {
            if singles(p, &s, all) { continue }
            if lookahead(p, &s, all) {
                hardest = max(hardest, .medium)
                continue
            }
            if subsets(p, &s) {
                hardest = max(hardest, .hard)
                continue
            }
            return .expert
        }
        return hardest
    }

    private static func units(_ p: Puzzle) -> [[Int]] {
        let n = p.size
        var rows = [[Int]](repeating: [], count: n)
        var cols = [[Int]](repeating: [], count: n)
        var regs = [[Int]](repeating: [], count: n)
        for cell in 0..<(n * n) {
            rows[cell / n].append(cell)
            cols[cell % n].append(cell)
            regs[p.regions[cell]].append(cell)
        }
        return rows + cols + regs
    }

    private static func sameLine(_ p: Puzzle, _ a: Int, _ b: Int) -> Bool {
        a / p.size == b / p.size || a % p.size == b % p.size || p.regions[a] == p.regions[b]
    }

    private static func place(_ p: Puzzle, _ s: inout State, _ cell: Int) {
        s.cats.insert(cell)
        for i in 0..<(p.size * p.size) where i != cell && sameLine(p, i, cell) {
            s.cand[i] = false
        }
        for n in Rules.neighbours(p.size, cell) { s.cand[n] = false }
    }

    private static func blocked(_ p: Puzzle, _ cell: Int) -> Set<Int> {
        var out = Set(Rules.neighbours(p.size, cell))
        for i in 0..<(p.size * p.size) where i != cell && sameLine(p, i, cell) {
            out.insert(i)
        }
        return out
    }

    private static func singles(_ p: Puzzle, _ s: inout State, _ all: [[Int]]) -> Bool {
        for u in all {
            if u.contains(where: { s.cats.contains($0) }) { continue }
            let open = u.filter { s.cand[$0] }
            if open.count == 1 {
                place(p, &s, open[0])
                return true
            }
        }
        return false
    }

    private static func lookahead(_ p: Puzzle, _ s: inout State, _ all: [[Int]]) -> Bool {
        let open = all.filter { u in !u.contains(where: { s.cats.contains($0) }) }
        for cell in 0..<(p.size * p.size) {
            if !s.cand[cell] || s.cats.contains(cell) { continue }
            let gone = blocked(p, cell)
            let empties = open.contains { u in
                !u.contains(cell) && u.allSatisfy { x in !s.cand[x] || gone.contains(x) }
            }
            if empties {
                s.cand[cell] = false
                return true
            }
        }
        return false
    }

    private static func combos(_ n: Int, _ k: Int) -> [[Int]] {
        var out: [[Int]] = []
        var pick: [Int] = []
        func go(_ start: Int) {
            if pick.count == k {
                out.append(pick)
                return
            }
            var i = start
            while i < n {
                pick.append(i)
                go(i + 1)
                pick.removeLast()
                i += 1
            }
        }
        go(0)
        return out
    }

    private enum Key { case row, col, reg }

    private static func subsets(_ p: Puzzle, _ s: inout State) -> Bool {
        let n = p.size
        func key(_ k: Key, _ cell: Int) -> Int {
            switch k {
            case .row: cell / n
            case .col: cell % n
            case .reg: p.regions[cell]
            }
        }
        let pairs: [(Key, Key)] = [(.reg, .row), (.reg, .col), (.row, .reg), (.col, .reg)]
        let openCells = (0..<(n * n)).filter { s.cand[$0] && !s.cats.contains($0) }
        for (groupBy, lineBy) in pairs {
            // groups in order of first appearance, like a JS Map
            var ids: [Int] = []
            var groups: [Int: [Int]] = [:]
            for cell in openCells {
                let g = key(groupBy, cell)
                if groups[g] == nil {
                    ids.append(g)
                    groups[g] = []
                }
                groups[g]!.append(cell)
            }
            let maxK = min(4, ids.count - 1)
            if maxK < 1 { continue }
            for k in 1...maxK {
                for pick in combos(ids.count, k) {
                    let chosen = Set(pick.map { ids[$0] })
                    var lines = Set<Int>()
                    for g in chosen { for cell in groups[g]! { lines.insert(key(lineBy, cell)) } }
                    if lines.count != k { continue }
                    var changed = false
                    for cell in openCells
                    where lines.contains(key(lineBy, cell)) && !chosen.contains(key(groupBy, cell)) && s.cand[cell] {
                        s.cand[cell] = false
                        changed = true
                    }
                    if changed { return true }
                }
            }
        }
        return false
    }
}
