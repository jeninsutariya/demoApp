import CatLogicKit
import SwiftUI

struct LeaderboardView: View {
    @Environment(AppModel.self) private var app
    @Environment(Router.self) private var router
    @State private var model: LeaderboardModel?

    var body: some View {
        ScrollView {
            if let model {
                content(model)
            }
        }
        .background(Tokens.Colors.bg)
        .navigationTitle("Today's fastest")
        .task {
            let m = model ?? LeaderboardModel(app: app)
            model = m
            await m.load()
        }
    }

    private func content(_ m: LeaderboardModel) -> some View {
        VStack(alignment: .leading, spacing: Tokens.space[3]) {
            Text("Daily puzzle · \(Format.date(m.date))").textStyle(Tokens.TextScale.sm, Tokens.Colors.textMuted)

            if case .loaded(.ok(_, true)) = m.state {
                Text("Sample leaderboard: the other names are placeholders until online play is switched on.")
                    .textStyle(Tokens.TextScale.sm)
                    .card()
            }
            if m.mine?.status != .solved {
                VStack(alignment: .leading, spacing: Tokens.space[1]) {
                    Text("Solve today's puzzle to get on the board.").textStyle(Tokens.TextScale.sm)
                    Button("Play the daily") { router.push(.puzzle(.daily(m.date))) }
                        .buttonStyle(TokenButtonStyle(variant: .primary, height: Tokens.Layout.cellMinTouch))
                }
                .card()
            }

            switch m.state {
            case .loading:
                ForEach(0..<8, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: Tokens.Radius.sm).fill(Tokens.Colors.border).frame(height: 44)
                }
                .accessibilityLabel("Loading")
            case .loaded(.offline):
                Text("You're offline. Your time is saved and will be sent when you're back online.")
                    .textStyle(Tokens.TextScale.base, Tokens.Colors.textMuted).padding(.top, Tokens.space[6])
            case .loaded(.error):
                VStack(spacing: Tokens.space[2]) {
                    Text("The leaderboard didn't load.").textStyle(Tokens.TextScale.base, Tokens.Colors.danger)
                    Button("Try again") { Task { await m.load() } }.buttonStyle(.secondary)
                }
                .padding(.top, Tokens.space[6])
            case .loaded(.ok(let rows, _)) where rows.isEmpty:
                Text("No times yet today. Be the first.").textStyle(Tokens.TextScale.base, Tokens.Colors.textMuted)
                    .padding(.top, Tokens.space[6])
            case .loaded(.ok):
                LazyVStack(spacing: 0) {
                    ForEach(m.visibleRows) { row in
                        HStack(spacing: Tokens.space[3]) {
                            Text("#\(row.rank)")
                                .textStyle(Tokens.TextScale.sm, row.rank <= 3 ? Tokens.Colors.warning : Tokens.Colors.textMuted)
                                .monospacedDigit()
                                .frame(width: 44, alignment: .leading)
                            Text(row.name).textStyle(Tokens.TextScale.sm).lineLimit(1)
                            Spacer()
                            Text(Format.time(row.timeMs)).textStyle(Tokens.TextScale.sm).monospacedDigit()
                        }
                        .padding(.vertical, Tokens.space[3])
                        .padding(.horizontal, Tokens.space[2])
                        .background(row.isMe ? Tokens.Colors.regions[6] : .clear, in: RoundedRectangle(cornerRadius: Tokens.Radius.sm))
                        .overlay(alignment: .bottom) { Tokens.Colors.border.frame(height: 1) }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("\(row.isMe ? "You, " : "")rank \(row.rank), \(row.name), \(Format.time(row.timeMs))")
                    }
                }
            }
        }
        .padding(.vertical, Tokens.space[2])
        .page()
    }
}
