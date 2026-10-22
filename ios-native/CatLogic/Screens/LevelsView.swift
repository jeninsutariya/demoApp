import CatLogicKit
import SwiftUI

struct LevelsView: View {
    @Environment(AppModel.self) private var app
    @Environment(Router.self) private var router
    @State private var records: [Int: LevelRecord] = [:]

    private var open: Int { (records.keys.max() ?? 0) + 1 }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: Tokens.space[2])], spacing: Tokens.space[2]) {
                    ForEach(1...LevelPack.count, id: \.self) { n in
                        tile(n).id(n)
                    }
                }
                .padding(.vertical, Tokens.space[2])
                .page()
            }
            .onAppear {
                records = app.store.levels
                proxy.scrollTo(open, anchor: .center)
            }
        }
        .background(Tokens.Colors.bg)
        .navigationTitle("Levels")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Text("\(records.count)/\(LevelPack.count)").textStyle(Tokens.TextScale.sm, Tokens.Colors.textMuted)
            }
        }
    }

    private func tile(_ n: Int) -> some View {
        let size = LevelPack.all[n - 1].size
        let paid = !app.isPlayable(level: n)
        let locked = n > open || paid
        let rec = records[n]
        return Button {
            if paid { router.showUnlock = true } else { router.push(.puzzle(.level(n))) }
        } label: {
            VStack(spacing: 2) {
                if paid {
                    Text("\(n)").textStyle(Tokens.TextScale.lg, Tokens.Colors.textMuted)
                } else if locked {
                    Image(systemName: "lock.fill").foregroundStyle(Tokens.Colors.textMuted)
                } else {
                    Text("\(n)").textStyle(Tokens.TextScale.lg)
                }
                Text("\(size)×\(size)").textStyle(Tokens.TextScale.xs, Tokens.Colors.textMuted)
                if let rec {
                    Label(Format.time(rec.bestMs), systemImage: "checkmark")
                        .labelStyle(.titleAndIcon)
                        .textStyle(Tokens.TextScale.xs, Tokens.Colors.success)
                        .monospacedDigit()
                }
            }
            .frame(maxWidth: .infinity, minHeight: 76)
            .background(locked ? Tokens.Colors.bg : Tokens.Colors.surface, in: RoundedRectangle(cornerRadius: Tokens.Radius.md))
            .overlay(
                RoundedRectangle(cornerRadius: Tokens.Radius.md)
                    .strokeBorder(n == open ? Tokens.Colors.accent : Tokens.Colors.border,
                                  lineWidth: n == open ? Tokens.BorderWidth.focus : 1)
            )
        }
        .buttonStyle(PressScale())
        .disabled(locked && !paid)
        .accessibilityLabel(paid ? "Level \(n), part of the unlock" : locked ? "Level \(n), locked"
                                   : "Level \(n), \(size) by \(size)\(rec.map { ", solved in \(Format.time($0.bestMs))" } ?? "")")
    }
}
