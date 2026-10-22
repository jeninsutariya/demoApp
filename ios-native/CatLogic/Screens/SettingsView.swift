import CatLogicKit
import SwiftUI

struct SettingsView: View {
    @Environment(AppModel.self) private var app
    @Environment(Router.self) private var router
    @State private var confirmDelete = false
    @State private var deleted = false

    var body: some View {
        @Bindable var app = app
        Form {
            Section {
                Toggle("Vibration", isOn: $app.settings.haptics)
                Toggle(isOn: $app.settings.sound) {
                    Text("Sound")
                    Text("Sounds are not in the game yet.")
                }
                Toggle("Hide the timer", isOn: $app.settings.hideTimer)
                Toggle(isOn: $app.settings.regionPatterns) {
                    Text("Region shapes")
                    Text("Adds a small shape to each colour, for telling regions apart without colour.")
                }
            }
            Section {
                Button("How to play") { router.showTutorial = true }
                LabeledContent("Restore purchase", value: "Not set up yet")
                LabeledContent("Privacy", value: "Progress stays on this device")
                Button(deleted ? "Leaderboard data deleted" : "Delete my leaderboard data", role: .destructive) {
                    confirmDelete = true
                }
                .disabled(deleted)
            }
            #if DEBUG
            Section("Developer") {
                Button("Design system") { router.push(.design) }
            }
            #endif
        }
        .font(.token(Tokens.TextScale.base))
        .tint(Tokens.Colors.accent)
        .scrollContentBackground(.hidden)
        .background(Tokens.Colors.bg)
        .navigationTitle("Settings")
        .confirmationDialog("Delete your leaderboard data?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                Task {
                    try? await app.leaderboard.deleteMe()
                    deleted = true
                }
            }
        } message: {
            Text("Your name and daily times are removed from the leaderboard. Progress on this device stays.")
        }
    }
}
