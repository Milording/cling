import SwiftUI

struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @Binding var showDev: Bool
    @State private var launchAtLogin = LoginItem.isEnabled
    @State private var loginError: String?

    /// SMAppService only works from a real .app bundle, not `swift run`.
    private var isBundled: Bool { Bundle.main.bundleIdentifier != nil }

    var body: some View {
        @Bindable var model = model
        VStack(alignment: .leading, spacing: 14) {
            Text("Settings")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Toggle(isOn: $launchAtLogin) {
                Text("Launch at login").font(.system(size: 12.5))
            }
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
            if !isBundled {
                Text("Available when running the bundled Cling.app")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            if let loginError {
                Text(loginError)
                    .font(.caption)
                    .foregroundStyle(Theme.coral)
            }

            Toggle(isOn: $model.devMode) {
                Text("Dev mode").font(.system(size: 12.5))
            }
            .onChange(of: model.devMode) { _, newValue in
                if !newValue { showDev = false }
            }

            Text("Cling tracks Claude Code activity from local transcripts. Nothing leaves your Mac.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .toggleStyle(.switch)
        .controlSize(.small)
        .tint(Theme.accent)
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
