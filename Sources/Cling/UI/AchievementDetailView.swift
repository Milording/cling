import SwiftUI

/// Full-popover detail for a tapped medal: a big 3D medal you can spin,
/// the title and description, an unlocked/locked pill, and share actions.
struct AchievementDetailView: View {
    let achievement: Achievement
    let unlockDate: Date?
    let onClose: () -> Void

    @Environment(AppModel.self) private var model
    @State private var orientation: ShareCardLayout = .horizontal

    private var unlocked: Bool { unlockDate != nil }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(.quaternary.opacity(0.6)))
                }
                .buttonStyle(.plain)
                .help("Close")
            }

            Spacer(minLength: 8)

            MedalView(achievement: achievement, unlocked: unlocked, diameter: 190)

            Text(achievement.name)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .padding(.top, 26)

            Text(achievement.blurb)
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 6)
                .padding(.horizontal, 24)

            statusPill
                .padding(.top, 18)

            if unlocked {
                shareControls
                    .padding(.top, 22)
            }

            Spacer(minLength: 8)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    @ViewBuilder
    private var statusPill: some View {
        if let date = unlockDate {
            Text("Unlocked · \(achievement.points)P")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(achievement.tier.color)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Capsule().fill(achievement.tier.color.opacity(0.16)))
                .help("Unlocked \(date.formatted(date: .abbreviated, time: .shortened))")
        } else {
            VStack(spacing: 8) {
                Text("Locked · \(achievement.points)P")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(.quaternary.opacity(0.6)))
                if let fraction = model.progress(for: achievement.id) {
                    ProgressBar(fraction: fraction, color: achievement.tier.color)
                        .frame(width: 180)
                    Text(model.progressCaption(for: achievement.id) ?? "")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }

    private var shareControls: some View {
        VStack(spacing: 12) {
            Picker("", selection: $orientation) {
                Text("Post").tag(ShareCardLayout.horizontal)
                Text("Story").tag(ShareCardLayout.vertical)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 180)

            HStack(spacing: 14) {
                shareButton
                actionButton(icon: "doc.on.doc", label: "Copy") {
                    if let data = pngData() { ShareCardRenderer.copyToPasteboard(data) }
                }
                actionButton(icon: "square.and.arrow.down", label: "Save") {
                    if let data = pngData() {
                        ShareCardRenderer.savePanel(for: achievement, data: data, layout: orientation)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var shareButton: some View {
        if let date = unlockDate,
           let url = ShareCardRenderer.temporaryPNG(for: achievement, unlockDate: date,
                                                    layout: orientation) {
            ShareLink(item: url, preview: SharePreview("\(achievement.name) — Cling",
                                                       image: Image(nsImage: NSImage(byReferencing: url)))) {
                buttonBody(icon: "paperplane", label: "Share")
            }
            .buttonStyle(.plain)
        }
    }

    private func actionButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) { buttonBody(icon: icon, label: label) }
            .buttonStyle(.plain)
    }

    private func buttonBody(icon: String, label: String) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .frame(width: 44, height: 44)
                .background(Circle().fill(.quaternary.opacity(0.6)))
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .foregroundStyle(.primary)
    }

    private func pngData() -> Data? {
        guard let date = unlockDate else { return nil }
        return ShareCardRenderer.pngData(for: achievement, unlockDate: date, layout: orientation)
    }
}
