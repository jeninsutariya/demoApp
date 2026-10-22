import CatLogicKit
import SwiftUI

// The one place the purchase is offered. Shown from a locked level, the
// win sheet, Home and Settings. One price, no subscription.
struct UnlockView: View {
    @Environment(AppModel.self) private var app
    @Environment(Purchases.self) private var purchases
    @Environment(\.dismiss) private var dismiss

    private var more: Int { LevelPack.count - LevelPack.freeLevels }

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.space[3]) {
            if app.allLevelsUnlocked {
                Text("Every level is open").textStyle(Tokens.TextScale.xl)
                Text("Thank you for supporting Napspot.").textStyle(Tokens.TextScale.base, Tokens.Colors.textMuted)
                Spacer()
                Button("Back to the puzzles") { dismiss() }.buttonStyle(.primary)
            } else {
                Text("\(more) more levels").textStyle(Tokens.TextScale.xl)
                Text("Up to 10×10, getting harder as you go. The daily board and the first \(LevelPack.freeLevels) levels stay free either way.")
                    .textStyle(Tokens.TextScale.base, Tokens.Colors.textMuted)
                VStack(alignment: .leading, spacing: Tokens.space[1]) {
                    Label("One payment. No subscription, nothing to cancel.", systemImage: "checkmark")
                    Label("Never any ads.", systemImage: "checkmark")
                    Label("Shared with your family.", systemImage: "checkmark")
                }
                .textStyle(Tokens.TextScale.sm)

                switch purchases.state {
                case .pending:
                    Text("Waiting for approval. The levels open as soon as it goes through.")
                        .textStyle(Tokens.TextScale.sm, Tokens.Colors.textMuted)
                case .failed(let message):
                    Text(message).textStyle(Tokens.TextScale.sm, Tokens.Colors.danger)
                default:
                    EmptyView()
                }
                Spacer()
                if let product = purchases.product {
                    Button("Unlock for \(product.displayPrice)") {
                        Task { await purchases.buy(app: app) }
                    }
                    .buttonStyle(.primary)
                    .disabled(purchases.state == .buying)
                } else if purchases.loadFailed {
                    Text("The App Store isn't reachable right now. Try again in a moment.")
                        .textStyle(Tokens.TextScale.sm, Tokens.Colors.textMuted)
                    Button("Try again") { Task { await purchases.loadProduct() } }.buttonStyle(.secondary)
                } else {
                    ProgressView().frame(maxWidth: .infinity)
                }
                Button("Restore purchase") { Task { await purchases.restore(app: app) } }
                    .buttonStyle(.ghost)
                    .disabled(purchases.state == .buying)
            }
        }
        .padding(Tokens.space[5])
        .presentationDetents([.medium, .large])
        .presentationBackground(Tokens.Colors.surface)
        .onChange(of: app.allLevelsUnlocked) { _, open in
            if open { purchases.state = .idle }
        }
    }
}
