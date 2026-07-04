import SwiftUI

/// Test surface: preview toasts, force-unlock, inject synthetic events, reset.
struct DevModeView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let _ = model.stateVersion // re-evaluate unlock state after engine changes
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Dev mode")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                VStack(spacing: 4) {
                    ForEach(Achievements.all) { achievement in
                        HStack(spacing: 8) {
                            LucideText(icon: achievement.icon, size: 13)
                                .foregroundStyle(achievement.tier.color)
                                .frame(width: 18)
                            Text(achievement.name)
                                .font(.system(size: 11.5))
                                .lineLimit(1)
                            Spacer()
                            devButton("Toast") { model.devPreview(achievement) }
                            devButton("Unlock") { model.devUnlock(achievement) }
                                .disabled(model.engine.isUnlocked(achievement.id))
                        }
                    }
                }

                Text("Inject events")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 6) {
                    devButton("Send a message") {
                        model.handle([.user(text: "Hello from dev mode",
                                            timestamp: .now, sessionID: devSession)])
                    }
                    devButton("+1M tokens (Millionaire I)") {
                        model.handle([.assistant(usage: Usage(input: 500_000, output: 500_000),
                                                 model: "claude-sonnet-4", timestamp: .now,
                                                 sessionID: devSession)])
                    }
                    devButton("+15 please/thank you") {
                        let text = Array(repeating: "please", count: 15).joined(separator: " ")
                        model.handle([.user(text: text, timestamp: .now, sessionID: devSession)])
                    }
                    devButton("10 nights (Night Owl I)") {
                        let base = next1AM()
                        model.handle((0..<10).map {
                            .user(text: "night", timestamp: base.addingTimeInterval(Double($0) * 86400),
                                  sessionID: devSession)
                        })
                    }
                    devButton("3 sessions at once (Multitasker)") {
                        model.handle((0..<3).map {
                            .user(text: "hi", timestamp: .now, sessionID: "dev-session-\($0)")
                        })
                    }
                    devButton("/doctor ×10") {
                        model.handle((0..<10).map { _ in
                            .slashCommand(name: "doctor", timestamp: .now, sessionID: devSession)
                        })
                    }
                    devButton("10 git commits") {
                        model.handle((0..<10).map { _ in
                            .toolUse(name: "Bash", input: "{\"command\":\"git commit -m x\"}",
                                     timestamp: .now, sessionID: devSession)
                        })
                    }
                    devButton("100 interruptions (Rage Quit I)") {
                        model.handle((0..<100).map { _ in
                            .interrupted(timestamp: .now, sessionID: devSession)
                        })
                    }
                }

                Divider()

                Button {
                    model.devReset()
                } label: {
                    Label("Reset all progress", systemImage: "arrow.counterclockwise")
                        .font(.system(size: 11.5))
                        .foregroundStyle(Theme.coral)
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxHeight: .infinity)
    }

    private var devSession: String { "dev-session" }

    private func next1AM() -> Date {
        let calendar = Calendar.current
        let oneAM = calendar.date(bySettingHour: 1, minute: 0, second: 0, of: .now)!
        return oneAM > .now ? oneAM : calendar.date(byAdding: .day, value: 1, to: oneAM)!
    }

    private func devButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(RoundedRectangle(cornerRadius: 6).fill(.quaternary.opacity(0.6)))
        }
        .buttonStyle(.plain)
    }
}
