import SwiftUI

struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @Binding var showDev: Bool
    @State private var launchAtLogin = LoginItem.isEnabled
    @State private var loginError: String?
    @AppStorage("soundEnabled") private var soundEnabled = true

    /// SMAppService only works from a real .app bundle, not `swift run`.
    private var isBundled: Bool { Bundle.main.bundleIdentifier != nil }

    var body: some View {
        @Bindable var model = model
        Form {
            Section {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .disabled(!isBundled)
                    .onChange(of: launchAtLogin) { _, newValue in
                        do {
                            try LoginItem.set(enabled: newValue)
                            loginError = nil
                        } catch {
                            loginError = error.localizedDescription
                            launchAtLogin = LoginItem.isEnabled
                        }
                    }

                Toggle("Play sound on unlock", isOn: $soundEnabled)

                Toggle("Dev mode", isOn: $model.devMode)
                    .onChange(of: model.devMode) { _, newValue in
                        if !newValue { showDev = false }
                    }
            } header: {
                Text("General")
            } footer: {
                VStack(alignment: .leading, spacing: 6) {
                    if !isBundled {
                        Text("Launch at login is available when running the bundled Cling.app.")
                    }
                    if let loginError {
                        Text(loginError).foregroundStyle(Theme.coral)
                    }
                    Text("Cling reads Claude Code activity from local transcripts. Nothing ever leaves your Mac.")
                }
                .font(.callout)
                .foregroundStyle(.secondary)
                .padding(.top, 2)
            }
        }
        .formStyle(.grouped)
        .tint(Theme.accent)
    }
}
