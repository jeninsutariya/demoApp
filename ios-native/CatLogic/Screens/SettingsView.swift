import CatLogicKit
import SwiftUI

struct SettingsView: View {
    @Environment(AppModel.self) private var app
    @Environment(Router.self) private var router
    @Environment(GameCenterAuth.self) private var gameCenter

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
            }
            Section {
                if gameCenter.isSignedIn {
                    LabeledContent("Signed in as", value: gameCenter.playerName ?? "")
                    Button("Open Game Center") { gameCenter.showDashboard() }
                } else {
                    LabeledContent("Not signed in", value: "")
                }
            } header: {
                Text("Game Center")
            } footer: {
                Text("Daily times post to Game Center. Sign in or out, or hide your name, in the Settings app under Game Center.")
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
    }
}
