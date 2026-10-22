public enum Rules {
    // The 8 cells around a cell, in the same order as engine/rules.ts
    public static func neighbours(_ size: Int, _ cell: Int) -> [Int] {
        let r = cell / size, c = cell % size
        var out: [Int] = []
        for dr in -1...1 {
            for dc in -1...1 where !(dr == 0 && dc == 0) {
                let rr = r + dr, cc = c + dc
                if rr >= 0, rr < size, cc >= 0, cc < size { out.append(rr * size + cc) }
            }
        }
        return out
    }

    // Up, down, left, right. Order matters: the generator's choices depend on it.
    public static func orthogonal(_ size: Int, _ cell: Int) -> [Int] {
        let r = cell / size, c = cell % size
        var out: [Int] = []
        if r > 0 { out.append(cell - size) }
        if r < size - 1 { out.append(cell + size) }
        if c > 0 { out.append(cell - 1) }
        if c < size - 1 { out.append(cell + 1) }
        return out
    }

    public static func isValidSolution(_ p: Puzzle, cats: [Int]) -> Bool {
        let size = p.size
        guard cats.count == size, cats.allSatisfy({ $0 >= 0 && $0 < size * size }) else { return false }
        guard Set(cats.map { $0 / size }).count == size,
              Set(cats.map { $0 % size }).count == size,
              Set(cats.map { p.regions[$0] }).count == size else { return false }
        let set = Set(cats)
        return cats.allSatisfy { cell in neighbours(size, cell).allSatisfy { !set.contains($0) } }
    }

    public static func regionsConnected(_ p: Puzzle) -> Bool {
        let size = p.size
        for g in 0..<size {
            let cells = p.regions.indices.filter { p.regions[$0] == g }
            guard let first = cells.first else { return false }
            var seen: Set<Int> = [first]
            var stack = [first]
            while let cell = stack.popLast() {
                for n in orthogonal(size, cell) where p.regions[n] == g && !seen.contains(n) {
                    seen.insert(n)
                    stack.append(n)
                }
            }
            if seen.count != cells.count { return false }
        }
        return true
    }
}
