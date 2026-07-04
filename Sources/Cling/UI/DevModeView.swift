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
                        model.handle([.userMessage(text: "Hello from dev mode",
                                                   timestamp: .now, sessionID: devSession)])
                    }
                    devButton("+250k output tokens") {
                        model.handle([.assistantMessage(outputTokens: 250_000,
                                                        timestamp: .now, sessionID: devSession)])
                    }
                    devButton("+10 please/thank you") {
                        let text = Array(repeating: "please", count: 10).joined(separator: " ")
                        model.handle([.userMessage(text: text, timestamp: .now, sessionID: devSession)])
                    }
                    devButton("Message at 1 AM (Night Owl)") {
                        model.handle([.userMessage(text: "night shift",
                                                   timestamp: next1AM(), sessionID: devSession)])
                    }
                    devButton("5 conversations today (Multitasker)") {
                        let events = (0..<5).map {
                            TranscriptEvent.userMessage(text: "hi", timestamp: .now,
                                                        sessionID: "dev-session-\($0)")
                        }
                        model.handle(events)
                    }
                    devButton("31-minute wait (Homunculus)") {
                        model.handle([
                            .userMessage(text: "are you there?", timestamp: .now, sessionID: "dev-wait"),
                            .assistantMessage(outputTokens: 1, timestamp: .now.addingTimeInterval(31 * 60),
                                              sessionID: "dev-wait"),
                        ])
                    }
                    devButton("6-hour streak (Marathon)") {
                        let start = Date.now
                        let events = stride(from: 0.0, through: Achievements.marathonGoal, by: 25)
                            .map { TranscriptEvent.activity(timestamp: start.addingTimeInterval($0),
                                                            sessionID: "dev-marathon") }
                        model.handle(events)
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
