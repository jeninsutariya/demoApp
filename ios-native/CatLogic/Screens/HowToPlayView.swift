import CatLogicKit
import SwiftUI

struct HowToPlayView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var page = 0

    struct Rule {
        let title: String
        let body: String
        let cells: [CellState]
        var lives: Int?
    }

    private static let demo = LevelPack.all[0]

    private let rules: [Rule] = {
        let p = HowToPlayView.demo
        let n = p.size
        let answer = p.solutionCells
        let first = answer[0]
        let middle = answer[n / 2]
        func board(cats: [Int], marks: [Int]) -> [CellState] {
            var cells = [CellState](repeating: .empty, count: n * n)
            for i in marks { cells[i] = .mark }
            for i in cats { cells[i] = .cat }
            return cells
        }
        let all = Array(0..<(n * n))
        return [
            Rule(title: "One cat per row and column",
                 body: "Every row and every column holds exactly one cat.",
                 cells: board(cats: [first], marks: all.filter { $0 != first && ($0 / n == 0 || $0 % n == first % n) })),
            Rule(title: "One cat per colour",
                 body: "Each coloured region holds exactly one cat too.",
                 cells: board(cats: [middle], marks: all.filter { $0 != middle && p.regions[$0] == p.regions[middle] })),
            Rule(title: "Cats need their space",
                 body: "No two cats touch, not even corner to corner.",
                 cells: board(cats: [middle], marks: Rules.neighbours(n, middle))),
            Rule(title: "Three lives, no guessing",
                 body: "A cat in the wrong place costs a life. Every board has one answer you can reach by logic. Tap to mark cells a cat can't be in, tap again for a cat.",
                 cells: board(cats: Array(answer.prefix(2)), marks: []),
                 lives: 2),
        ]
    }()

    var body: some View {
        VStack(spacing: Tokens.space[4]) {
            Text("How to play").textStyle(Tokens.TextScale.lg).padding(.top, Tokens.space[4])
            TabView(selection: $page) {
                ForEach(rules.indices, id: \.self) { i in
                    let rule = rules[i]
                    VStack(spacing: Tokens.space[3]) {
                        BoardView(puzzle: Self.demo, cells: rule.cells, locked: true, width: 240)
                        if let lives = rule.lives { LivesView(lives: lives) }
                        Text(rule.title).textStyle(Tokens.TextScale.lg).multilineTextAlignment(.center)
                        Text(rule.body).textStyle(Tokens.TextScale.base, Tokens.Colors.textMuted).multilineTextAlignment(.center)
                    }
                    .card()
                    .padding(.horizontal, Tokens.Layout.gutter)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Rule \(i + 1) of \(rules.count). \(rule.title). \(rule.body)")
                    .tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            VStack(spacing: Tokens.space[2]) {
                Button(page == rules.count - 1 ? "Start playing" : "Next") {
                    if page == rules.count - 1 { finish() } else { withAnimation { page += 1 } }
                }
                .buttonStyle(.primary)
                Button(page == 0 ? "Skip" : "Back") {
                    if page == 0 { finish() } else { withAnimation { page -= 1 } }
                }
                .buttonStyle(.ghost)
            }
            .page()
        }
        .background(Tokens.Colors.bg)
    }

    private func finish() {
        app.store.setFlag("seenTutorial", true)
        dismiss()
    }
}
