import CatLogicKit
import SwiftUI

// Every primitive in its states, for checking the design system on a device.
// Reached from Settings in debug builds.
struct DesignView: View {
    private let p = LevelPack.all[45]
    private var cells: [CellState] {
        p.regions.indices.map { $0 == p.solution[0] ? .cat : $0 % 7 == 3 ? .mark : .empty }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.space[6]) {
                section("Type") {
                    let scale: [(String, Tokens.TextStyle)] = [
                        ("xs", Tokens.TextScale.xs), ("sm", Tokens.TextScale.sm), ("base", Tokens.TextScale.base),
                        ("lg", Tokens.TextScale.lg), ("xl", Tokens.TextScale.xl), ("display", Tokens.TextScale.display),
                    ]
                    ForEach(scale, id: \.0) { item in
                        Text("\(item.0) · The cat sat in row three").textStyle(item.1)
                    }
                }
                section("Regions") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5)) {
                        ForEach(Tokens.Colors.regions.indices, id: \.self) { i in
                            RoundedRectangle(cornerRadius: Tokens.Radius.sm).fill(Tokens.Colors.regions[i]).frame(height: 36)
                        }
                    }
                }
                section("Buttons") {
                    Button("Primary") {}.buttonStyle(.primary)
                    Button("Secondary") {}.buttonStyle(.secondary)
                    Button("Ghost") {}.buttonStyle(.ghost)
                    Button("Danger") {}.buttonStyle(.danger)
                    Button("Disabled") {}.buttonStyle(.primary).disabled(true)
                }
                section("Tools, lives, cat") {
                    HStack(spacing: Tokens.space[3]) {
                        ToolButton(systemImage: "arrow.uturn.backward", label: "Undo") {}
                        ToolButton(systemImage: "arrow.counterclockwise", label: "Restart") {}.disabled(true)
                        ToolButton(systemImage: "lightbulb", label: "Hint", badge: 2) {}
                        LivesView(lives: 1)
                        CatIcon().frame(width: 32)
                        CatIcon(color: Tokens.Colors.danger).frame(width: 32)
                    }
                }
                section("Board: marks, cat, mistake, hint") {
                    BoardView(puzzle: p, cells: cells, lastMistake: 3, hinted: p.size + p.solution[1], width: 340)
                }
                section("Board: region shapes on") {
                    BoardView(puzzle: p, cells: cells, patterns: true, locked: true, width: 340)
                }
            }
            .padding(.vertical, Tokens.space[4])
            .page()
        }
        .background(Tokens.Colors.bg)
        .navigationTitle("Design system")
    }

    private func section<Content: View>(_ title: String, @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Tokens.space[2]) {
            Text(title).textStyle(Tokens.TextScale.sm, Tokens.Colors.textMuted).fontWeight(.bold)
            content()
        }
    }
}
