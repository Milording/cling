import SwiftUI
import AppKit
import UniformTypeIdentifiers

@MainActor
enum ShareCardRenderer {
    static func pngData(for achievement: Achievement, unlockDate: Date,
                        layout: ShareCardLayout) -> Data? {
        let renderer = ImageRenderer(content: ShareCardView(achievement: achievement,
                                                            unlockDate: unlockDate,
                                                            layout: layout))
        renderer.scale = 1
        guard let cgImage = renderer.cgImage else { return nil }
        let rep = NSBitmapImageRep(cgImage: cgImage)
        return rep.representation(using: .png, properties: [:])
    }

    /// Writes the card to a temp file (nice filename for share sheets and drags).
    static func temporaryPNG(for achievement: Achievement, unlockDate: Date,
                             layout: ShareCardLayout) -> URL? {
        guard let data = pngData(for: achievement, unlockDate: unlockDate, layout: layout) else {
            return nil
        }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Cling-\(achievement.id)-\(layout.rawValue).png")
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            NSLog("Cling: failed to write share card: \(error)")
            return nil
        }
    }

    static func copyToPasteboard(_ data: Data) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setData(data, forType: .png)
    }

    static func savePanel(for achievement: Achievement, data: Data, layout: ShareCardLayout) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.nameFieldStringValue = "Cling-\(achievement.name)-\(layout.rawValue).png"
        NSApp.activate(ignoringOtherApps: true)
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            try? data.write(to: url, options: .atomic)
        }
    }
}

/// Share actions shown in an unlocked achievement's expanded detail.
struct ShareBar: View {
    let achievement: Achievement
    let unlockDate: Date
    @State private var cardURLs: [ShareCardLayout: URL] = [:]
    @State private var copied = false

    var body: some View {
        HStack(spacing: 8) {
            ForEach(ShareCardLayout.allCases) { layout in
                if let url = cardURLs[layout] {
                    ShareLink(item: url, preview: SharePreview(
                        "\(achievement.name) — Cling", image: Image(nsImage: NSImage(byReferencing: url)))) {
                        chip(icon: .share, label: layout.label)
                    }
                    .buttonStyle(.plain)
                }
            }
            Button {
                if let data = ShareCardRenderer.pngData(for: achievement, unlockDate: unlockDate,
                                                        layout: .horizontal) {
                    ShareCardRenderer.copyToPasteboard(data)
                    copied = true
                    Task {
                        try? await Task.sleep(for: .seconds(1.5))
                        copied = false
                    }
                }
            } label: {
                chip(icon: copied ? .check : .share, label: copied ? "Copied" : "Copy")
            }
            .buttonStyle(.plain)
            Button {
                if let data = ShareCardRenderer.pngData(for: achievement, unlockDate: unlockDate,
                                                        layout: .vertical) {
                    ShareCardRenderer.savePanel(for: achievement, data: data, layout: .vertical)
                }
            } label: {
                chip(icon: .share, label: "Save\u{2026}")
            }
            .buttonStyle(.plain)
        }
        .task {
            for layout in ShareCardLayout.allCases where cardURLs[layout] == nil {
                cardURLs[layout] = ShareCardRenderer.temporaryPNG(
                    for: achievement, unlockDate: unlockDate, layout: layout)
            }
        }
    }

    private func chip(icon: LucideIcon, label: String) -> some View {
        HStack(spacing: 5) {
            LucideText(icon: icon, size: 11)
            Text(label).font(.system(size: 11, weight: .medium, design: .rounded))
        }
        .foregroundStyle(.primary)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(RoundedRectangle(cornerRadius: 7).fill(.quaternary.opacity(0.6)))
    }
}
