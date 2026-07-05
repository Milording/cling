import SwiftUI
import AppKit

/// Full-popover detail for a tapped medal: the medal, its title and description,
/// an unlocked/locked pill, and (once unlocked) share previews + actions.
struct AchievementDetailView: View {
    let achievement: Achievement
    let unlockDate: Date?
    let onClose: () -> Void

    @Environment(AppModel.self) private var model
    @State private var orientation: ShareCardLayout = .horizontal
    @State private var thumbnails: [ShareCardLayout: NSImage] = [:]
    @AppStorage("useRealityKit") private var useRealityKit = false
    /// Replaces the ScrollView + live coin with static equivalents for screenshots.
    var staticRender = false

    private var unlocked: Bool { unlockDate != nil }
    private var masked: Bool { achievement.hidden && !unlocked }
    private var dateText: String {
        unlockDate?.formatted(date: .abbreviated, time: .omitted) ?? ""
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            content
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(.quaternary.opacity(0.7)))
            }
            .buttonStyle(.plain)
            .help("Close")
            .padding(12)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .task { await loadThumbnails() }
    }

    @ViewBuilder
    private var content: some View {
        if staticRender {
            inner
        } else {
            ScrollView { inner }
        }
    }

    private var inner: some View {
        VStack(spacing: 0) {
                    medal
                        .padding(.top, 20)

                    Text(masked ? "???" : achievement.name)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .padding(.top, 18)

                    Text(masked ? "A hidden achievement. Keep using Claude Code to discover it."
                                : achievement.blurb)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 5)
                        .padding(.horizontal, 24)

                    statusPill
                        .padding(.top, 14)

                    if unlocked {
                        shareControls
                            .padding(.top, 18)
                    }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var medal: some View {
        if staticRender, unlocked, !masked {
            Circle().fill(achievement.tier.color).frame(width: 180, height: 180)
        } else if unlocked, !masked {
            coin
                .frame(width: 180, height: 180)
        } else {
            // Locked (or hidden): a static, non-rotatable outline.
            AchievementBadge(achievement: achievement, unlocked: false, size: 150,
                             hiddenLocked: masked)
                .frame(height: 180)
        }
    }

    @ViewBuilder
    private var coin: some View {
        if useRealityKit, #available(macOS 15.0, *) {
            CoinMedalRealityView(achievement: achievement, unlocked: true, backText: dateText)
        } else {
            CoinMedalView(achievement: achievement, unlocked: true, backText: dateText)
        }
    }

    @ViewBuilder
    private var statusPill: some View {
        if unlocked {
            Text("Unlocked · \(achievement.points)P")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(achievement.tier.color)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Capsule().fill(achievement.tier.color.opacity(0.16)))
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

    // MARK: - Share

    private var shareControls: some View {
        VStack(spacing: 14) {
            HStack(spacing: 16) {
                ForEach(ShareCardLayout.allCases) { layout in tile(layout) }
            }
            HStack(spacing: 20) {
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

    private func tile(_ layout: ShareCardLayout) -> some View {
        let selected = orientation == layout
        return VStack(spacing: 6) {
            Group {
                if let image = thumbnails[layout] {
                    Image(nsImage: image).resizable().scaledToFill()
                } else {
                    Rectangle().fill(.quaternary.opacity(0.5))
                }
            }
            .frame(width: 118, height: 66)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(
                selected ? Theme.accent : Color.secondary.opacity(0.25),
                lineWidth: selected ? 2 : 1))
            Text(layout.label)
                .font(.caption)
                .foregroundStyle(selected ? AnyShapeStyle(Theme.accent) : AnyShapeStyle(.secondary))
        }
        .contentShape(Rectangle())
        .onTapGesture { orientation = layout }
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
                .frame(width: 42, height: 42)
                .background(Circle().fill(.quaternary.opacity(0.6)))
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .foregroundStyle(.primary)
    }

    private func pngData() -> Data? {
        guard let date = unlockDate else { return nil }
        return ShareCardRenderer.pngData(for: achievement, unlockDate: date, layout: orientation)
    }

    private func loadThumbnails() async {
        guard let date = unlockDate else { return }
        for layout in ShareCardLayout.allCases where thumbnails[layout] == nil {
            if let data = ShareCardRenderer.pngData(for: achievement, unlockDate: date, layout: layout),
               let image = NSImage(data: data) {
                thumbnails[layout] = image
            }
        }
    }
}
