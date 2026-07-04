import SwiftUI

/// A medal that reads as a real 3D object: a stack of thin slices gives it
/// thickness and a metallic edge, and dragging horizontally spins it around
/// its vertical axis like a coin.
struct MedalView: View {
    let achievement: Achievement
    let unlocked: Bool
    var diameter: CGFloat = 190
    /// Starting rotation; useful for previews/screenshots.
    var initialAngle: Double = 0

    @State private var angle: Double = 0
    @State private var lastAngle: Double = 0

    private var thickness: CGFloat { diameter * 0.13 }
    private let slices = 28

    private static let chrome = LinearGradient(
        colors: [Color(white: 0.97), Color(white: 0.62), Color(white: 0.90),
                 Color(white: 0.52), Color(white: 0.82)],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    var body: some View {
        let rad = angle * .pi / 180
        let cosA = cos(rad)
        let sinA = sin(rad)

        let absCos = abs(cosA)
        // Interior slices keep a minimum width so their offset copies tile into a
        // solid metallic edge when the medal is seen (nearly) side-on.
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
                            .fill(Self.chrome)
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
        .gesture(
            DragGesture()
                .onChanged { angle = lastAngle + Double($0.translation.width) * 0.7 }
                .onEnded { _ in lastAngle = angle }
        )
        .accessibilityLabel("\(achievement.name) medal. Drag to rotate.")
        .onAppear {
            angle = initialAngle
            lastAngle = initialAngle
        }
    }

    private func depth(_ i: Int) -> CGFloat {
        (CGFloat(i) / CGFloat(slices - 1) - 0.5) * thickness
    }

    private var innerFill: AnyShapeStyle {
        unlocked
            ? AnyShapeStyle(LinearGradient(
                colors: [achievement.tier.color, achievement.tier.color.opacity(0.62)],
                startPoint: .topLeading, endPoint: .bottomTrailing))
            : AnyShapeStyle(LinearGradient(
                colors: [Color(white: 0.55), Color(white: 0.4)],
                startPoint: .topLeading, endPoint: .bottomTrailing))
    }

    private func face(front: Bool) -> some View {
        ZStack {
            Circle().fill(Self.chrome)                       // metallic rim
            Circle().fill(innerFill).padding(diameter * 0.085)
            Circle()                                         // soft top sheen
                .fill(LinearGradient(colors: [.white.opacity(0.28), .clear],
                                     startPoint: .top, endPoint: .center))
                .padding(diameter * 0.085)
            if front {
                LucideText(icon: achievement.icon, size: diameter * 0.34)
                    .foregroundStyle(unlocked ? .white : Color(white: 0.85))
            } else {
                VStack(spacing: 2) {
                    LucideText(icon: .trophy, size: diameter * 0.24)
                    Text("+\(achievement.points)P")
                        .font(.system(size: diameter * 0.11, weight: .bold, design: .rounded))
                }
                .foregroundStyle(unlocked ? .white : Color(white: 0.85))
            }
        }
    }
}
