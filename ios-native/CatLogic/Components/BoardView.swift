import CatLogicKit
import SwiftUI

struct BoardView: View {
    let puzzle: SolvedPuzzle
    let cells: [CellState]
    var lastMistake: Int?
    var shakes = 0 // bumps on every mistake
    var hinted: Int?
    var patterns = false
    var locked = false
    let width: CGFloat
    var onTap: (Int) -> Void = { _ in }
    var onPlace: (Int) -> Void = { _ in }
    var onClear: (Int) -> Void = { _ in }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var lastTap: (cell: Int, at: Date)?

    static let regionNames = ["pink", "peach", "yellow", "lime", "mint", "sky", "periwinkle", "lavender", "tan", "grey"]
    // One shape per region, for players who can't tell the colours apart
    static let patternGlyphs = ["•", "◦", "▪", "▫", "▴", "▵", "◆", "◇", "+", "–"]
    static let doubleTap: TimeInterval = 0.3

    init(puzzle: SolvedPuzzle, cells: [CellState], lastMistake: Int? = nil, shakes: Int = 0, hinted: Int? = nil,
         patterns: Bool = false, locked: Bool = false, width: CGFloat,
         onTap: @escaping (Int) -> Void = { _ in }, onPlace: @escaping (Int) -> Void = { _ in },
         onClear: @escaping (Int) -> Void = { _ in }) {
        self.puzzle = puzzle
        self.cells = cells
        self.lastMistake = lastMistake
        self.shakes = shakes
        self.hinted = hinted
        self.patterns = patterns
        self.locked = locked
        self.width = width
        self.onTap = onTap
        self.onPlace = onPlace
        self.onClear = onClear
    }

    private var n: Int { puzzle.size }
    private var cell: CGFloat { (width / CGFloat(n)).rounded(.down) }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<n, id: \.self) { r in
                HStack(spacing: 0) {
                    ForEach(0..<n, id: \.self) { c in
                        cellView(r * n + c, r: r, c: c)
                    }
                }
            }
        }
        .overlay { edges.allowsHitTesting(false) }
        .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.md))
        .overlay(RoundedRectangle(cornerRadius: Tokens.Radius.md).strokeBorder(Tokens.Colors.regionEdge, lineWidth: Tokens.BorderWidth.region))
        .frame(width: cell * CGFloat(n), height: cell * CGFloat(n))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(n) by \(n) puzzle")
    }

    // Grid lines inside regions, thick lines between them
    private var edges: some View {
        Canvas { ctx, _ in
            for pass in 0..<2 {
                let thick = pass == 1
                for r in 0..<n {
                    for c in 0..<n {
                        let i = r * n + c
                        if c < n - 1, (puzzle.regions[i] != puzzle.regions[i + 1]) == thick {
                            line(&ctx, CGPoint(x: CGFloat(c + 1) * cell, y: CGFloat(r) * cell), CGPoint(x: CGFloat(c + 1) * cell, y: CGFloat(r + 1) * cell), thick)
                        }
                        if r < n - 1, (puzzle.regions[i] != puzzle.regions[i + n]) == thick {
                            line(&ctx, CGPoint(x: CGFloat(c) * cell, y: CGFloat(r + 1) * cell), CGPoint(x: CGFloat(c + 1) * cell, y: CGFloat(r + 1) * cell), thick)
                        }
                    }
                }
            }
        }
    }

    private func line(_ ctx: inout GraphicsContext, _ a: CGPoint, _ b: CGPoint, _ thick: Bool) {
        var p = Path()
        p.move(to: a)
        p.addLine(to: b)
        ctx.stroke(p, with: .color(thick ? Tokens.Colors.regionEdge : Tokens.Colors.gridLine),
                   style: StrokeStyle(lineWidth: thick ? Tokens.BorderWidth.region : Tokens.BorderWidth.grid, lineCap: thick ? .square : .butt))
    }

    @ViewBuilder
    private func cellView(_ i: Int, r: Int, c: Int) -> some View {
        let g = puzzle.regions[i]
        let state = cells[i]
        let isMistake = lastMistake == i
        ZStack(alignment: .topLeading) {
            Tokens.Colors.regions[g]
            if patterns {
                Text(Self.patternGlyphs[g])
                    .font(.system(size: cell * 0.28))
                    .foregroundStyle(Tokens.Colors.mark.opacity(0.55))
                    .padding(.leading, 3)
            }
            Group {
                switch state {
                case .cat:
                    CatIcon().frame(width: cell * 0.72).transition(.scale(scale: 0.6).combined(with: .opacity))
                case .mark:
                    Image(systemName: "xmark")
                        .font(.system(size: cell * 0.36, weight: .heavy))
                        .foregroundStyle(isMistake ? Tokens.Colors.danger : Tokens.Colors.mark)
                case .empty:
                    Color.clear
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .modifier(Shake(animatableData: isMistake && !reduceMotion ? CGFloat(shakes) : 0))
        }
        .frame(width: cell, height: cell)
        .overlay {
            if hinted == i || isMistake {
                Rectangle()
                    .strokeBorder(isMistake ? Tokens.Colors.danger : Tokens.Colors.accent, lineWidth: isMistake ? 2 : Tokens.BorderWidth.focus)
                    .padding(isMistake ? 2 : 4)
            }
        }
        .animation(reduceMotion ? nil : .spring(duration: Tokens.Motion.place), value: state)
        .animation(reduceMotion ? nil : .linear(duration: Tokens.Motion.shake), value: shakes)
        .contentShape(Rectangle())
        .onTapGesture { press(i) }
        .onLongPressGesture(minimumDuration: 0.45) { if !locked { onClear(i) } }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Row \(r + 1), column \(c + 1), \(Self.regionNames[g]) region, \(word(state))")
        .accessibilityAddTraits(.isButton)
        .accessibilityHint(locked ? "" : "Marks the cell. Again for a cat.")
        .accessibilityAction { if !locked { onTap(i) } }
        .accessibilityAction(named: "Place cat") { if !locked { onPlace(i) } }
        .accessibilityAction(named: "Clear") { if !locked { onClear(i) } }
    }

    private func word(_ s: CellState) -> String {
        switch s {
        case .cat: "cat"
        case .mark: "marked"
        case .empty: "empty"
        }
    }

    // Tap cycles empty, mark, cat. A second quick tap on the same cell is a
    // double tap and places a cat directly.
    private func press(_ i: Int) {
        guard !locked else { return }
        let now = Date()
        if let last = lastTap, last.cell == i, now.timeIntervalSince(last.at) < Self.doubleTap {
            lastTap = nil
            onPlace(i)
        } else {
            lastTap = (i, now)
            onTap(i)
        }
    }
}

struct Shake: GeometryEffect {
    var animatableData: CGFloat
    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: 6 * sin(animatableData * .pi * 4), y: 0))
    }
}
