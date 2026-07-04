import SwiftUI
import SceneKit

/// Interactive 3D coin medal: drag to spin it horizontally, with inertia on release.
struct CoinMedalView: NSViewRepresentable {
    let achievement: Achievement
    let unlocked: Bool

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> SCNView {
        let view = SCNView()
        view.backgroundColor = .clear
        view.antialiasingMode = .multisampling4X
        view.rendersContinuously = true            // smooth spin + live reflections
        view.allowsCameraControl = false

        let (scene, pivot, cameraNode) = CoinMedal.makeScene(achievement: achievement,
                                                             unlocked: unlocked)
        view.scene = scene
        view.pointOfView = cameraNode
        context.coordinator.pivot = pivot
        context.coordinator.view = view

        let pan = NSPanGestureRecognizer(target: context.coordinator,
                                         action: #selector(Coordinator.handlePan(_:)))
        view.addGestureRecognizer(pan)
        return view
    }

    func updateNSView(_ nsView: SCNView, context: Context) {}

    @MainActor
    final class Coordinator: NSObject {
        weak var view: SCNView?
        var pivot: SCNNode?
        var angle: Double = 0            // radians
        var base: Double = 0
        var inertiaTask: Task<Void, Never>?

        private let sensitivity = 0.011  // radians per point dragged

        @objc func handlePan(_ gesture: NSPanGestureRecognizer) {
            guard let view else { return }
            switch gesture.state {
            case .began:
                inertiaTask?.cancel()
                base = angle
            case .changed:
                let dx = Double(gesture.translation(in: view).x)
                angle = base + dx * sensitivity
                apply()
            case .ended, .cancelled:
                startInertia(velocity: Double(gesture.velocity(in: view).x) * sensitivity)
            default:
                break
            }
        }

        private func startInertia(velocity: Double) {
            inertiaTask?.cancel()
            var v = max(-30, min(30, velocity))     // rad/sec, clamped
            guard abs(v) > 0.25 else { return }
            inertiaTask = Task { @MainActor [weak self] in
                while !Task.isCancelled, abs(v) > 0.1 {
                    guard let self else { return }
                    self.angle += v / 60
                    v *= 0.95
                    self.apply()
                    try? await Task.sleep(nanoseconds: 16_000_000)
                }
            }
        }

        private func apply() {
            pivot?.eulerAngles = SCNVector3(0, CGFloat(angle), 0)
        }
    }
}
