import CatLogicKit
import SwiftUI

struct PuzzleScreen: View {
    let route: PuzzleRoute
    @Environment(AppModel.self) private var app
    @Environment(Router.self) private var router
    @State private var session: PuzzleSession?
    @State private var missing = false

    init(route: PuzzleRoute) { self.route = route }

    var body: some View {
        Group {
            if let session {
                PuzzleView(session: session)
            } else if missing {
                ContentUnavailableView {
                    Label("This board isn't here", systemImage: "questionmark.square.dashed")
                } description: {
                    Text("That puzzle doesn't exist, or it's a daily from another day. Today's is on the home screen.")
                } actions: {
                    Button("Go home") { router.home() }.buttonStyle(.primary)
                }
            } else {
                ProgressView()
            }
        }
        .background(Tokens.Colors.bg)
        .onAppear {
            guard session == nil, !missing else { return }
            session = PuzzleSession(route: route, app: app)
            missing = session == nil
        }
    }
}

struct PuzzleView: View {
    let session: PuzzleSession
    @Environment(AppModel.self) private var app
    @Environment(Router.self) private var router
    @Environment(\.scenePhase) private var phase
    @State private var onScreen = false
    @State private var sheet: SheetKind?

    init(session: PuzzleSession) { self.session = session }

    enum SheetKind: String, Identifiable {
        case hint, failed, solved
        var id: String { rawValue }
    }

    private var game: Game { session.game }
    private var playing: Bool { game.status == .playing && session.solvedBefore == nil }

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: Tokens.space[4]) {
                    Text("\(session.puzzle.size)×\(session.puzzle.size) · \(session.puzzle.difficulty.label)")
                        .textStyle(Tokens.TextScale.sm, Tokens.Colors.textMuted)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    BoardView(
                        puzzle: session.puzzle,
                        cells: game.cells,
                        lastMistake: game.lastMistake,
                        shakes: game.mistakes,
                        hinted: game.hinted,
                        patterns: app.settings.regionPatterns,
                        locked: !playing,
                        width: min(geo.size.width - 2 * Tokens.Layout.gutter, Tokens.Layout.boardMax),
                        onTap: { session.act(.tap($0)) },
                        onPlace: { session.act(.place($0)) },
                        onClear: { session.act(.clear($0)) }
                    )

                    if let done = session.solvedBefore {
                        VStack(spacing: Tokens.space[2]) {
                            Text("Done for today in \(Format.time(done.timeMs)). The next board appears at midnight UTC.")
                                .textStyle(Tokens.TextScale.base).multilineTextAlignment(.center)
                            Button("See the leaderboard") { router.push(.leaderboard) }.buttonStyle(.primary)
                            Button("Play levels") { router.replaceTop(.levels) }.buttonStyle(.secondary)
                        }
                    } else {
                        HStack(spacing: Tokens.space[3]) {
                            ToolButton(systemImage: "arrow.uturn.backward", label: "Undo") { session.act(.undo) }
                                .disabled(game.history.isEmpty || !playing)
                            ToolButton(systemImage: "arrow.counterclockwise", label: "Restart") { session.restart() }
                                .disabled(!playing)
                            ToolButton(systemImage: "lightbulb", label: "Hint", badge: session.hints) { sheet = .hint }
                                .disabled(!playing)
                        }
                        Text("Tap once to rule a spot out. Tap again, or double tap, to place a cat. Hold to clear.")
                            .textStyle(Tokens.TextScale.xs, Tokens.Colors.textMuted)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.top, Tokens.space[2])
                .page()
            }
        }
        .background(Tokens.Colors.bg)
        .navigationTitle(session.kind == .daily ? "Daily · \(Format.date(session.key))" : session.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if !app.settings.hideTimer {
                    TimelineView(.periodic(from: .now, by: 1)) { ctx in
                        Text(Format.time(session.elapsed(at: ctx.date)))
                            .textStyle(Tokens.TextScale.sm, Tokens.Colors.textMuted)
                            .monospacedDigit()
                    }
                }
                LivesView(lives: game.lives)
            }
        }
        .sensoryFeedback(trigger: session.feedbackCount) { _, _ in
            guard app.settings.haptics else { return nil }
            switch session.feedback {
            case .place: return .impact(weight: .light)
            case .mistake: return .warning
            case .solved: return .success
            case .none: return nil
            }
        }
        .onAppear {
            onScreen = true
            session.setVisible(phase == .active)
        }
        .onDisappear {
            onScreen = false
            session.setVisible(false)
        }
        .onChange(of: phase) { _, p in session.setVisible(onScreen && p == .active) }
        .onChange(of: game.status) { _, status in
            if session.solvedBefore != nil { return }
            sheet = status == .failed ? .failed : status == .solved ? .solved : nil
        }
        .onChange(of: sheet) { _, s in session.setSheetOpen(s != nil) }
        .sheet(item: $sheet) { kind in
            VStack(alignment: .leading, spacing: Tokens.space[2]) { sheetContent(kind) }
                .padding(Tokens.space[5])
                .presentationDetents([.medium])
                .presentationBackground(Tokens.Colors.surface)
                .interactiveDismissDisabled(kind != .hint)
        }
    }

    @ViewBuilder
    private func sheetContent(_ kind: SheetKind) -> some View {
        switch kind {
        case .hint:
            let left = session.hints
            Text(left > 0 ? "Want a hint?" : "No hints left").textStyle(Tokens.TextScale.lg)
            Text(left > 0 ? "A hint rings the spot you're closest to working out. You have \(left)."
                          : "Finish today's board to earn another.")
                .textStyle(Tokens.TextScale.base, Tokens.Colors.textMuted)
            Spacer()
            if left > 0 {
                Button("Show me") {
                    sheet = nil
                    session.spendHint()
                }
                .buttonStyle(.primary)
            }
            Button(left > 0 ? "Keep thinking" : "OK") { sheet = nil }.buttonStyle(.secondary)

        case .failed:
            Text("That's three slips").textStyle(Tokens.TextScale.xl)
            Text(session.kind == .daily ? "Same board, fresh lives. The clock keeps running, so there's no rush."
                                         : "Every board can be solved by logic alone. Have another go.")
                .textStyle(Tokens.TextScale.base, Tokens.Colors.textMuted)
            Spacer()
            Button("Start fresh") {
                sheet = nil
                session.restart()
            }
            .buttonStyle(.primary)
            Button("Home") {
                sheet = nil
                router.home()
            }
            .buttonStyle(.secondary)

        case .solved:
            let r = session.result
            Text("Every cat found its spot").textStyle(Tokens.TextScale.xl)
            Text("Time \(Format.time(r?.timeMs ?? session.elapsed())) · \(game.mistakes == 0 ? "no mistakes" : "\(game.mistakes) mistake\(game.mistakes > 1 ? "s" : "")")")
                .textStyle(Tokens.TextScale.base).monospacedDigit()
            if let best = r?.bestMs {
                Text("Best \(Format.time(best))").textStyle(Tokens.TextScale.base, Tokens.Colors.textMuted).monospacedDigit()
            }
            if let rank = r?.rank, let total = r?.total {
                Text("#\(rank) of \(total) today").textStyle(Tokens.TextScale.base, Tokens.Colors.textMuted)
            }
            if let note = session.submitNote {
                Text(note).textStyle(Tokens.TextScale.sm, Tokens.Colors.textMuted)
            }
            Spacer()
            if session.kind == .level {
                if let next = session.nextLevel {
                    Button("Level \(next)") {
                        sheet = nil
                        router.replaceTop(.puzzle(.level(next)))
                    }
                    .buttonStyle(.primary)
                }
                Button("All levels") {
                    sheet = nil
                    router.replaceTop(.levels)
                }
                .buttonStyle(.secondary)
            } else {
                Text("You earned a hint.").textStyle(Tokens.TextScale.sm, Tokens.Colors.success)
                Button("See the leaderboard") {
                    sheet = nil
                    router.replaceTop(.leaderboard)
                }
                .buttonStyle(.primary)
                Button("Home") {
                    sheet = nil
                    router.home()
                }
                .buttonStyle(.secondary)
            }
        }
    }
}
