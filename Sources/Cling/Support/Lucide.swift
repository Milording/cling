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

    // Expanded achievement set.
    case sparkles = "\u{e412}"
    case coins = "\u{e097}"
    case banknote = "\u{e052}"
    case gem = "\u{e242}"
    case dollarSign = "\u{e0b1}"
    case circleDollarSign = "\u{e47d}"
    case badgeDollarSign = "\u{e476}"
    case sunrise = "\u{e179}"
    case flame = "\u{e0d2}"
    case tent = "\u{e227}"
    case palmtree = "\u{e281}"
    case undo = "\u{e2a1}"
    case frown = "\u{e0db}"
    case skull = "\u{e221}"
    case ghost = "\u{e20e}"
    case crown = "\u{e1d6}"
    case clover = "\u{e092}"
    case eraser = "\u{e28f}"
    case type = "\u{e198}"
    case copy = "\u{e09e}"
    case stethoscope = "\u{e2f1}"
    case messageSquare = "\u{e117}"
    case brain = "\u{e3c6}"
    case database = "\u{e0ad}"
    case folder = "\u{e0d7}"
    case folders = "\u{e33f}"
    case plug = "\u{e37f}"
    case plugZap = "\u{e45c}"
    case gitCommit = "\u{e0e3}"
    case shield = "\u{e158}"
    case shieldAlert = "\u{e1fe}"
    case scissors = "\u{e14e}"
    case badgeCheck = "\u{e241}"
    case circleStop = "\u{e083}"
    case coffee = "\u{e096}"
    case rocket = "\u{e286}"
    case ship = "\u{e3ba}"
    case creditCard = "\u{e0aa}"
    case medal = "\u{e36f}"
    case graduationCap = "\u{e234}"
    case music = "\u{e122}"
    case star = "\u{e176}"
    case award = "\u{e04f}"
    case pilcrow = "\u{e3a3}"
    case zap = "\u{e1b4}"
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
