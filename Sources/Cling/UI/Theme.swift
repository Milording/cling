import SwiftUI

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
}

extension View {
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
