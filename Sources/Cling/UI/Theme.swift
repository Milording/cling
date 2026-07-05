import SwiftUI
import AppKit

/// App palette: #ee6055 #60d394 #aaf683 #ffd97d #ff9b85 plus system black/white shades.
/// UI chrome otherwise uses semantic system colors and materials (HIG-native).
enum Theme {
    static let coral = Color(hex: 0xEE6055)
    static let green = Color(hex: 0x60D394)
    static let lime = Color(hex: 0xAAF683)
    static let yellow = Color(hex: 0xFFD97D)
    static let peach = Color(hex: 0xFF9B85)

    static let accent = coral
}

extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }

    /// Lighten (positive) or darken (negative) by adjusting HSB brightness.
    func adjustingBrightness(by delta: CGFloat) -> Color {
        let ns = NSColor(self).usingColorSpace(.sRGB) ?? NSColor.gray
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ns.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return Color(hue: Double(h), saturation: Double(s),
                     brightness: Double(max(0, min(1, b + delta))), opacity: Double(a))
    }
}

extension View {
    /// A floating white/elevated card surface with a soft shadow, used across the popover.
    func cardSurface(cornerRadius: CGFloat = 16) -> some View {
        background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor)))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.05), lineWidth: 1))
            .compositingGroup()
            .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
    }

    /// Liquid Glass where available, translucent material otherwise.
    @ViewBuilder
    func glassCapsule() -> some View {
        if #available(macOS 26.0, *) {
            glassEffect(.regular, in: Capsule())
        } else {
            background(.ultraThinMaterial, in: Capsule())
                .background(Capsule().fill(.black.opacity(0.25)))
        }
    }
}
