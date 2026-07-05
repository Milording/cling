import SwiftUI

struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @Binding var showDev: Bool
    @State private var launchAtLogin = LoginItem.isEnabled
    @State private var loginError: String?
    @State private var confirmRecalculate = false
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("useRealityKit") private var useRealityKit = false

    /// SMAppService only works from a real .app bundle, not `swift run`.
    private var isBundled: Bool { Bundle.main.bundleIdentifier != nil }

    var body: some View {
        @Bindable var model = model
        Form {
            Section {
                LabeledContent("Connection") {
                    HStack(spacing: 6) {
                        Circle().fill(model.status.color).frame(width: 8, height: 8)
                        Text(model.status.label).foregroundStyle(.secondary)
                    }
                }

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

                if #available(macOS 15.0, *) {
                    Toggle("Medal renderer: RealityKit (experimental)", isOn: $useRealityKit)
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

            // Moved to the bottom.
            Section {
                LabeledContent {
                    Button {
                        confirmRecalculate = true
                    } label: {
                        if model.isRecalculating {
                            HStack(spacing: 6) {
                                ProgressView().controlSize(.small)
                                Text("Recalculating\u{2026}")
                            }
                        } else {
                            Text("Recalculate\u{2026}")
                        }
                    }
                    .disabled(model.isRecalculating)
                } label: {
                    Text("Recalculate Progress")
                    Text("Replay your full local Claude Code history to rebuild all achievement progress. Normally only activity since Cling was installed is counted.")
                }
            }
        }
        .formStyle(.grouped)
        .tint(Theme.accent)
        .alert("Recalculate progress?", isPresented: $confirmRecalculate) {
            Button("Cancel", role: .cancel) {}
            Button("Recalculate", role: .destructive) { model.recalculateFromLogs() }
        } message: {
            Text("All achievement progress will be rebuilt from your full local Claude Code history. This replaces your current progress.")
        }
    }
}
