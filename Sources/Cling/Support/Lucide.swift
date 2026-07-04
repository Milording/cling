import SwiftUI
import CoreText

/// Glyphs from the bundled Lucide icon font (lucide.ttf, family "lucide").
/// Codepoints come from lucide-static's font/info.json.
enum LucideIcon: String {
    case messageCircle = "\u{e116}"
    case swords = "\u{e2b4}"
    case droplet = "\u{e0b4}"
    case moon = "\u{e11e}"
    case layers = "\u{e529}"
    case heartHandshake = "\u{e2d7}"
    case hourglass = "\u{e296}"
    case footprints = "\u{e3b9}"
    case trophy = "\u{e373}"
    case settings = "\u{e154}"
    case share = "\u{e156}"
    case lock = "\u{e10b}"
    case flask = "\u{e0d5}"
    case rotateCCW = "\u{e148}"
    case power = "\u{e140}"
    case check = "\u{e226}"
    case close = "\u{e1b2}"
}

enum Lucide {
    /// Registers the bundled font once for this process.
    static let registered: Bool = {
        guard let url = Bundle.module.url(forResource: "lucide", withExtension: "ttf") else {
            NSLog("Cling: lucide.ttf missing from bundle")
            return false
        }
        var error: Unmanaged<CFError>?
        let ok = CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
        if !ok {
            NSLog("Cling: failed to register lucide.ttf: \(String(describing: error?.takeRetainedValue()))")
        }
        return ok
    }()

    static func font(size: CGFloat) -> Font {
        _ = registered
        return .custom("lucide", size: size)
    }
}

/// A single Lucide icon rendered as text.
struct LucideText: View {
    let icon: LucideIcon
    var size: CGFloat = 16

    var body: some View {
        Text(icon.rawValue).font(Lucide.font(size: size))
    }
}
