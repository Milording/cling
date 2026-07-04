import SwiftUI

/// A medal that reads as a real, shiny 3D object: a stack of thin slices gives
/// it thickness and a polished metallic edge, a reflective glare sweeps across
/// the face as it turns, and dragging spins it — with inertia when you let go.
struct MedalView: View {
    let achievement: Achievement
    let unlocked: Bool
    var diameter: CGFloat = 190
    /// Starting rotation; useful for previews/screenshots.
    var initialAngle: Double = 0

    @State private var angle: Double = 0
    @State private var velocity: Double = 0            // deg/sec, for inertia
    @State private var prevTranslation: Double = 0
    @State private var lastMoveTime: TimeInterval = 0
    @State private var inertia: Timer?

    private let sensitivity = 0.75
    private var thickness: CGFloat { diameter * 0.13 }
    private let slices = 28

    /// Polished, "turned metal" ring — alternating bright/dark stops catch light all around.
    private static let metal = AngularGradient(stops: [
        .init(color: Color(white: 0.99), location: 0.00),
        .init(color: Color(white: 0.55), location: 0.13),
        .init(color: Color(white: 0.93), location: 0.25),
        .init(color: Color(white: 0.50), location: 0.37),
        .init(color: Color(white: 0.99), location: 0.50),
        .init(color: Color(white: 0.55), location: 0.63),
        .init(color: Color(white: 0.90), location: 0.75),
        .init(color: Color(white: 0.48), location: 0.87),
        .init(color: Color(white: 0.99), location: 1.00),
    ], center: .center)

    var body: some View {
        let rad = angle * .pi / 180
        let cosA = cos(rad)
        let sinA = sin(rad)
        let absCos = abs(cosA)
        let bridge = thickness / CGFloat(slices - 1) * 2.4

        ZStack {
            ForEach(0..<slices, id: \.self) { i in
                Group {
                    if i == slices - 1 || i == 0 {
                        face(front: i == slices - 1)
                            .frame(width: diameter, height: diameter)
                            .scaleEffect(x: max(0.0015, absCos), y: 1)
                    } else {
                        Ellipse()
                            .fill(Self.metal)
                            .frame(width: max(diameter * absCos, bridge), height: diameter)
                    }
                }
                .offset(x: depth(i) * sinA)
                .zIndex(cosA >= 0 ? Double(i) : Double(slices - i))
            }
        }
        .frame(width: diameter + thickness, height: diameter)
        .background(
            Ellipse()
                .fill(.black.opacity(0.22))
                .frame(width: diameter * 0.72, height: 16)
                .blur(radius: 9)
                .offset(y: diameter * 0.52)
        )
        .contentShape(Rectangle())
        .gesture(dragGesture)
        .accessibilityLabel("\(achievement.name) medal. Drag to rotate.")
        .onAppear {
            angle = initialAngle
        }
        .onDisappear {
            inertia?.invalidate()
            inertia = nil
        }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                inertia?.invalidate()
                inertia = nil
                let now = Date().timeIntervalSinceReferenceDate
                let dt = max(1.0 / 240, now - lastMoveTime)
                let delta = Double(value.translation.width) - prevTranslation
                let dAngle = delta * sensitivity
                angle += dAngle
                velocity = dAngle / dt
                prevTranslation = Double(value.translation.width)
                lastMoveTime = now
            }
            .onEnded { _ in
                prevTranslation = 0
                startInertia()
            }
    }

    private func startInertia() {
        inertia?.invalidate()
        guard abs(velocity) > 12 else { return }
        velocity = max(-1400, min(1400, velocity))
        inertia = Timer.scheduledTimer(withTimeInterval: 1.0 / 60, repeats: true) { _ in
            MainActor.assumeIsolated {
                angle += velocity / 60
                velocity *= 0.955                  // friction
                if abs(velocity) < 6 {
                    inertia?.invalidate()
                    inertia = nil
                }
            }
        }
    }

    private func depth(_ i: Int) -> CGFloat {
        (CGFloat(i) / CGFloat(slices - 1) - 0.5) * thickness
    }

    private var innerFill: AnyShapeStyle {
        unlocked
            ? AnyShapeStyle(LinearGradient(
                colors: [achievement.tier.color, achievement.tier.color.opacity(0.6)],
                startPoint: .topLeading, endPoint: .bottomTrailing))
            : AnyShapeStyle(LinearGradient(
                colors: [Color(white: 0.56), Color(white: 0.4)],
                startPoint: .topLeading, endPoint: .bottomTrailing))
    }

    private func face(front: Bool) -> some View {
        let rim = diameter * 0.085
        return ZStack {
            Circle().fill(Self.metal)                              // polished metal ring
            Circle().stroke(.black.opacity(0.18), lineWidth: 1)    // rim seam
                .padding(rim * 0.5)

            Circle().fill(innerFill).padding(rim)                  // colored face

            // Domed spherical shading: highlight top-left, shadow bottom-right.
            Circle()
                .fill(RadialGradient(colors: [.white.opacity(0.4), .clear],
                                     center: .init(x: 0.32, y: 0.28),
                                     startRadius: 0, endRadius: diameter * 0.55))
                .padding(rim)
            Circle()
                .fill(RadialGradient(colors: [.clear, .black.opacity(0.22)],
                                     center: .init(x: 0.7, y: 0.78),
                                     startRadius: diameter * 0.1, endRadius: diameter * 0.5))
                .padding(rim)

            content(front: front)

            glare.padding(rim)                                     // reflective sweep
        }
    }

    @ViewBuilder
    private func content(front: Bool) -> some View {
        let tint: Color = unlocked ? .white : Color(white: 0.85)
        if front {
            LucideText(icon: achievement.icon, size: diameter * 0.34)
                .foregroundStyle(tint)
                .shadow(color: .black.opacity(0.25), radius: 1, y: 1)
        } else {
            VStack(spacing: 2) {
                LucideText(icon: .trophy, size: diameter * 0.24)
                Text("+\(achievement.points)P")
                    .font(.system(size: diameter * 0.11, weight: .bold, design: .rounded))
            }
            .foregroundStyle(tint)
            .shadow(color: .black.opacity(0.25), radius: 1, y: 1)
        }
    }

    /// A diagonal light streak whose position tracks rotation, so it sweeps as the medal turns.
    private var glare: some View {
        let sweep = ((angle.truncatingRemainder(dividingBy: 360)) + 360)
            .truncatingRemainder(dividingBy: 360) / 360           // 0…1
        return Rectangle()
            .fill(LinearGradient(
                colors: [.clear, .white.opacity(0.5), .clear],
                startPoint: .leading, endPoint: .trailing))
            .frame(width: diameter * 0.42)
            .rotationEffect(.degrees(22))
            .offset(x: (sweep * 2 - 1) * diameter * 0.95)
            .frame(width: diameter, height: diameter)
            .clipShape(Circle())
            .blendMode(.screen)
            .allowsHitTesting(false)
    }
}
