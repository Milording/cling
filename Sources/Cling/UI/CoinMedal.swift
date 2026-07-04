import SceneKit
import AppKit
import SwiftUI

/// Builds and renders the 3D coin medal from the bundled `coin.usdz`, with the
/// achievement icon engraved on the front and "+xP" on the back. The coin's
/// metal is tinted to the achievement's tier.
@MainActor
enum CoinMedal {
    static let radius: CGFloat = 0.709
    static let halfThickness: CGFloat = 0.066

    /// Loaded once — extracting the coin geometry from the USDZ is not free.
    private static let coinGeometry: SCNGeometry? = {
        guard let url = Bundle.module.url(forResource: "coin", withExtension: "usdz"),
              let scene = try? SCNScene(url: url, options: nil) else {
            NSLog("Cling: coin.usdz missing from bundle")
            return nil
        }
        var found: SCNGeometry?
        scene.rootNode.enumerateHierarchy { node, _ in
            if let geo = node.geometry { found = geo }
        }
        return found?.copy() as? SCNGeometry
    }()

    /// A soft studio environment so the metal reads as polished and reflective.
    private static let environmentImage: NSImage = {
        let w = 1024, h = 512
        let img = NSImage(size: NSSize(width: w, height: h))
        img.lockFocus()
        NSGradient(colors: [NSColor(white: 1.0, alpha: 1),
                            NSColor(white: 0.72, alpha: 1),
                            NSColor(white: 0.45, alpha: 1)])!
            .draw(in: NSRect(x: 0, y: 0, width: w, height: h), angle: -90)
        for cx in [0.22, 0.55, 0.82] {
            let bx = CGFloat(cx) * CGFloat(w)
            NSColor.white.setFill()
            NSBezierPath(roundedRect: NSRect(x: bx - 45, y: CGFloat(h) * 0.25,
                                             width: 90, height: CGFloat(h) * 0.6),
                         xRadius: 45, yRadius: 45).fill()
        }
        img.unlockFocus()
        guard let tiff = img.tiffRepresentation, let ci = CIImage(data: tiff) else { return img }
        let blurred = ci.applyingFilter("CIGaussianBlur", parameters: ["inputRadius": 22])
            .cropped(to: ci.extent)
        let rep = NSCIImageRep(ciImage: blurred)
        let out = NSImage(size: rep.size)
        out.addRepresentation(rep)
        return out
    }()

    // MARK: - Scene

    /// Builds a scene and returns the pivot node (rotate its `eulerAngles.y` to spin).
    static func makeScene(achievement: Achievement, unlocked: Bool) -> (SCNScene, SCNNode, SCNNode) {
        let scene = SCNScene()
        let pivot = SCNNode()

        if let geometry = coinGeometry?.copy() as? SCNGeometry {
            let material = geometry.firstMaterial ?? SCNMaterial()
            material.lightingModel = .physicallyBased
            material.diffuse.contents = albedo(for: achievement.tier, unlocked: unlocked)
            material.metalness.contents = 1.0
            material.roughness.contents = unlocked ? 0.28 : 0.42
            geometry.firstMaterial = material

            let coin = SCNNode(geometry: geometry)
            coin.addChildNode(facePlane(iconImage(achievement.icon),
                                        z: halfThickness + 0.004, flip: false))
            coin.addChildNode(facePlane(textImage("+\(achievement.points)P"),
                                        z: -halfThickness - 0.004, flip: true))
            pivot.addChildNode(coin)
        }
        scene.rootNode.addChildNode(pivot)

        scene.lightingEnvironment.contents = environmentImage
        scene.lightingEnvironment.intensity = 2.2
        scene.background.contents = NSColor.clear

        let key = SCNLight()
        key.type = .directional
        key.intensity = 500
        let keyNode = SCNNode()
        keyNode.light = key
        keyNode.eulerAngles = SCNVector3(-0.5, 0.4, 0)
        scene.rootNode.addChildNode(keyNode)

        let camera = SCNCamera()
        camera.fieldOfView = 16
        camera.wantsHDR = true
        camera.bloomIntensity = 0.25
        camera.bloomThreshold = 0.9
        let cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, 0, 6.5)
        scene.rootNode.addChildNode(cameraNode)

        return (scene, pivot, cameraNode)
    }

    /// Offscreen render at a given rotation (radians). Used for screenshots/verification.
    static func snapshot(achievement: Achievement, unlocked: Bool,
                         angle: Double, size: CGFloat) -> NSImage {
        let (scene, pivot, cameraNode) = makeScene(achievement: achievement, unlocked: unlocked)
        pivot.eulerAngles = SCNVector3(0, CGFloat(angle), 0)
        let renderer = SCNRenderer(device: MTLCreateSystemDefaultDevice(), options: nil)
        renderer.scene = scene
        renderer.pointOfView = cameraNode
        return renderer.snapshot(atTime: 0, with: NSSize(width: size, height: size),
                                 antialiasingMode: .multisampling4X)
    }

    // MARK: - Pieces

    private static func albedo(for tier: Tier, unlocked: Bool) -> NSColor {
        guard unlocked else { return NSColor(white: 0.72, alpha: 1) }
        return NSColor(tier.color).usingColorSpace(.sRGB) ?? .systemYellow
    }

    private static func facePlane(_ image: NSImage, z: CGFloat, flip: Bool) -> SCNNode {
        let plane = SCNPlane(width: radius * 1.15, height: radius * 1.15)
        let material = SCNMaterial()
        material.diffuse.contents = image
        material.lightingModel = .constant
        material.isDoubleSided = false
        plane.materials = [material]
        let node = SCNNode(geometry: plane)
        node.position = SCNVector3(0, 0, z)
        if flip { node.eulerAngles = SCNVector3(0, CGFloat.pi, 0) }
        return node
    }

    static func iconImage(_ icon: LucideIcon) -> NSImage {
        _ = Lucide.registered
        return engraved(icon.rawValue, font: NSFont(name: "lucide", size: 300)
            ?? .systemFont(ofSize: 300))
    }

    static func textImage(_ string: String) -> NSImage {
        engraved(string, font: .systemFont(ofSize: 150, weight: .heavy))
    }

    /// White glyph/text with a soft drop shadow, on transparent — reads as raised enamel.
    private static func engraved(_ string: String, font: NSFont) -> NSImage {
        let px: CGFloat = 512
        let img = NSImage(size: NSSize(width: px, height: px))
        img.lockFocus()
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.35)
        shadow.shadowBlurRadius = 6
        shadow.shadowOffset = NSSize(width: 0, height: -4)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font, .foregroundColor: NSColor.white,
            .paragraphStyle: paragraph, .shadow: shadow,
        ]
        let attributed = NSAttributedString(string: string, attributes: attributes)
        let height = attributed.size().height
        attributed.draw(in: NSRect(x: 0, y: (px - height) / 2, width: px, height: height))
        img.unlockFocus()
        return img
    }
}
