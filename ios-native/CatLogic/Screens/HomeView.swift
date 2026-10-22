import CatLogicKit
import SwiftUI

struct HomeView: View {
    @Environment(AppModel.self) private var app
    @Environment(Router.self) private var router
    @State private var model: HomeModel?

    var body: some View {
        ScrollView {
            if let model {
                content(model)
            }
        }
        .background(Tokens.Colors.bg)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            if model == nil { model = HomeModel(app: app) } else { model?.reload() }
            if model?.needsTutorial == true { router.showTutorial = true }
        }
        .onChange(of: router.showTutorial) { _, showing in
            if !showing { model?.reload() }
        }
    }

    private func content(_ m: HomeModel) -> some View {
        VStack(alignment: .leading, spacing: Tokens.space[4]) {
            VStack(alignment: .leading, spacing: Tokens.space[1]) {
                Text("Cat Logic").textStyle(Tokens.TextScale.display, relativeTo: .largeTitle)
                    .accessibilityAddTraits(.isHeader)
                Text("One cat per row, column and colour.").textStyle(Tokens.TextScale.base, Tokens.Colors.textMuted)
            }
            .padding(.top, Tokens.space[7])
            .padding(.bottom, Tokens.space[2])

            Button { router.push(.puzzle(.daily(m.today))) } label: {
                VStack(alignment: .leading, spacing: Tokens.space[1]) {
                    HStack(spacing: Tokens.space[2]) {
                        Image(systemName: "calendar").foregroundStyle(Tokens.Colors.accent)
                        Text("Daily puzzle").textStyle(Tokens.TextScale.lg)
                        Spacer()
                        if m.streak > 0 {
                            Text("\(m.streak) day streak").textStyle(Tokens.TextScale.sm, Tokens.Colors.warning)
                        }
                    }
                    Text("\(Format.date(m.today)) · \(m.dailySize)×\(m.dailySize)").textStyle(Tokens.TextScale.base, Tokens.Colors.textMuted)
                    if let d = m.daily, d.status == .solved {
                        HStack(spacing: Tokens.space[1]) {
                            Image(systemName: "checkmark")
                            Text("Solved in \(Format.time(d.timeMs)). Next board in ") + Text(Daily.nextReset(), style: .relative)
                        }
                        .textStyle(Tokens.TextScale.sm, Tokens.Colors.success)
                        .padding(.top, Tokens.space[2])
                    } else {
                        Text("Play today's board").textStyle(Tokens.TextScale.sm, Tokens.Colors.accent).fontWeight(.bold)
                            .padding(.top, Tokens.space[2])
                    }
                }
                .card()
            }
            .buttonStyle(PressScale())

            Button { router.push(.puzzle(.level(m.next))) } label: {
                VStack(alignment: .leading, spacing: Tokens.space[1]) {
                    HStack(spacing: Tokens.space[2]) {
                        Image(systemName: "square.grid.3x3").foregroundStyle(Tokens.Colors.accent)
                        Text("Levels").textStyle(Tokens.TextScale.lg)
                    }
                    Text("\(m.solved) of \(LevelPack.count) solved").textStyle(Tokens.TextScale.base, Tokens.Colors.textMuted)
                    Text("\(m.solved > 0 ? "Continue" : "Start"): level \(m.next) · \(m.nextSize)×\(m.nextSize)")
                        .textStyle(Tokens.TextScale.sm, Tokens.Colors.accent).fontWeight(.bold)
                        .padding(.top, Tokens.space[2])
                }
                .card()
            }
            .buttonStyle(PressScale())

            HStack {
                link("All levels", "square.grid.3x3") { router.push(.levels) }
                link("Leaderboard", "trophy") { router.push(.leaderboard) }
                link("How to play", "book") { router.showTutorial = true }
                link("Settings", "gearshape") { router.push(.settings) }
            }
            .padding(.top, Tokens.space[4])
        }
        .page()
    }

    private func link(_ title: String, _ icon: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: Tokens.space[1]) {
                Image(systemName: icon).font(.system(size: 22)).foregroundStyle(Tokens.Colors.text)
                Text(title).textStyle(Tokens.TextScale.xs, Tokens.Colors.textMuted)
            }
            .frame(maxWidth: .infinity, minHeight: 56)
        }
        .buttonStyle(PressScale())
    }
}
