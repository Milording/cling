import SwiftUI
import RealityKit

/// Experimental RealityKit rendering of the coin medal. Toggle it on in Settings.
/// (Can't be verified offscreen here, so treat as experimental — the SceneKit
/// `CoinMedalView` is the default, verified path.)
@available(macOS 15.0, *)
struct CoinMedalRealityView: View {
    let achievement: Achievement
    let unlocked: Bool
    var backText: String = ""

    var body: some View {
        RealityView { content in
            guard let url = Bundle.module.url(forResource: "coin", withExtension: "usdz"),
                  let coin = try? await Entity(contentsOf: url) else { return }

            normalize(coin)
            tint(coin)
            await addFaces(to: coin)

            let root = Entity()
            root.addChild(coin)
            content.add(root)

            let sun = DirectionalLight()
            sun.light.intensity = 3000
            sun.look(at: .zero, from: [1, 1, 2], relativeTo: nil)
            content.add(sun)

            let fill = DirectionalLight()
            fill.light.intensity = 1200
            fill.look(at: .zero, from: [-1.5, 0.5, 1.5], relativeTo: nil)
            content.add(fill)
        }
        .realityViewCameraControls(.orbit)
    }

    private func normalize(_ entity: Entity) {
        let bounds = entity.visualBounds(relativeTo: nil)
        let maxExtent = max(bounds.extents.x, max(bounds.extents.y, bounds.extents.z))
        if maxExtent > 0 {
            entity.scale = SIMD3<Float>(repeating: 1.6 / maxExtent)
        }
        entity.position = -bounds.center * entity.scale.x
    }

    private func tint(_ entity: Entity) {
        let color = unlocked ? NSColor(achievement.tier.color) : NSColor(white: 0.72, alpha: 1)
        entity.forEachModel { model in
            guard var component = model.model else { return }
            component.materials = component.materials.map { material in
                guard var pbr = material as? PhysicallyBasedMaterial else { return material }
                pbr.baseColor = .init(tint: color)
                pbr.metallic = 1.0
                pbr.roughness = .init(floatLiteral: unlocked ? 0.28 : 0.42)
                return pbr
            }
            model.model = component
        }
    }

    private func addFaces(to coin: Entity) async {
        let bounds = coin.visualBounds(relativeTo: coin)
        let half = bounds.extents.z / 2 + 0.002
        let size = bounds.extents.x * 0.62

        if let icon = await facePlane(CoinMedal.iconImage(achievement.icon), size: size) {
            icon.position = [0, 0, half]
            coin.addChild(icon)
        }
        let back = backText.isEmpty ? "+\(achievement.points)P" : backText
        if let text = await facePlane(CoinMedal.textImage(back), size: size) {
            text.position = [0, 0, -half]
            text.orientation = simd_quatf(angle: .pi, axis: [0, 1, 0])
            coin.addChild(text)
        }
    }

    private func facePlane(_ image: NSImage, size: Float) async -> ModelEntity? {
        guard let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil),
              let texture = try? await TextureResource(image: cg, options: .init(semantic: .color))
        else { return nil }
        var material = UnlitMaterial()
        material.color = .init(tint: .white, texture: .init(texture))
        material.opacityThreshold = 0.5
        let mesh = MeshResource.generatePlane(width: size, height: size)
        return await ModelEntity(mesh: mesh, materials: [material])
    }
}

@available(macOS 15.0, *)
private extension Entity {
    /// Applies `body` to every descendant that has a model component.
    func forEachModel(_ body: (ModelEntity) -> Void) {
        if let model = self as? ModelEntity { body(model) }
        for child in children { child.forEachModel(body) }
    }
}
