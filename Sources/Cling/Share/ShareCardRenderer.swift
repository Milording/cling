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
