// Seeded random numbers, bit-for-bit the same as engine/rng.ts. The daily
// puzzle must come out identical in the app, on the web and on the server,
// so this file mirrors the TypeScript exactly. Never use the system RNG here.

public struct Rng {
    private var a: UInt32

    public init(seed: String) { a = Rng.hashSeed(seed) }
    public init(state: UInt32) { a = state }

    // cyrb53-style 32-bit hash over UTF-16 code units, like charCodeAt
    public static func hashSeed(_ seed: String) -> UInt32 {
        let units = Array(seed.utf16)
        let length = UInt32(truncatingIfNeeded: units.count)
        var h1: UInt32 = 0xdeadbeef ^ length
        var h2: UInt32 = 0x41c6ce57 ^ length
        for unit in units {
            let ch = UInt32(unit)
            h1 = (h1 ^ ch) &* 2654435761
            h2 = (h2 ^ ch) &* 1597334677
        }
        h1 = ((h1 ^ (h1 >> 16)) &* 2246822507) ^ ((h2 ^ (h2 >> 13)) &* 3266489909)
        return h1
    }

    // mulberry32, returns [0, 1)
    public mutating func next() -> Double {
        a = a &+ 0x6d2b79f5
        var t = a
        t = (t ^ (t >> 15)) &* (t | 1)
        t ^= t &+ ((t ^ (t >> 7)) &* (t | 61))
        return Double(t ^ (t >> 14)) / 4294967296.0
    }

    public mutating func int(_ n: Int) -> Int {
        Int((next() * Double(n)).rounded(.down))
    }

    public mutating func shuffled<T>(_ items: [T]) -> [T] {
        var a = items
        var i = a.count - 1
        while i > 0 {
            let j = int(i + 1)
            a.swapAt(i, j)
            i -= 1
        }
        return a
    }
}
