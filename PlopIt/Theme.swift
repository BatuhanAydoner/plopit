import SpriteKit
import SwiftUI

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        let a, r, g, b: UInt64
        switch cleaned.count {
        case 3:
            (a, r, g, b) = (255, (value >> 8) * 17, (value >> 4 & 0xF) * 17, (value & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, value >> 16, value >> 8 & 0xFF, value & 0xFF)
        case 8:
            (a, r, g, b) = (value >> 24, value >> 16 & 0xFF, value >> 8 & 0xFF, value & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

enum CosmicTheme {
    static let deepNavy = Color(hex: "0D1024")
    static let obsidian = Color(hex: "06070D")
    static let cyan = Color(hex: "00D2FF")
    static let electricBlue = Color(hex: "0066FF")
    static let neonPurple = Color(hex: "7A40F2")
    static let lilac = Color(hex: "B55FE6")
    static let neonPink = Color(hex: "FF3366")
    static let holeBlack = Color(hex: "08090C")

    static var screenBackground: some View {
        ZStack {
            LinearGradient(
                colors: [deepNavy, obsidian],
                startPoint: .top,
                endPoint: .bottom
            )
            RadialGradient(
                colors: [
                    cyan.opacity(0.14),
                    neonPurple.opacity(0.1),
                    .clear
                ],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 420
            )
            RadialGradient(
                colors: [
                    lilac.opacity(0.12),
                    .clear
                ],
                center: .bottomLeading,
                startRadius: 10,
                endRadius: 360
            )
        }
        .ignoresSafeArea()
    }

    static var playGradient: LinearGradient {
        LinearGradient(
            colors: [cyan, electricBlue],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var secondaryGradient: LinearGradient {
        LinearGradient(
            colors: [lilac, neonPurple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var dangerGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "FF5C8A"), neonPink],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var titleGradient: LinearGradient {
        LinearGradient(
            colors: [.white, cyan],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

enum SKCosmic {
    static let deepNavy = SKColor(red: 0.05, green: 0.06, blue: 0.14, alpha: 1)
    static let obsidian = SKColor(red: 0.02, green: 0.03, blue: 0.05, alpha: 1)
    static let cyan = SKColor(red: 0.0, green: 0.82, blue: 1.0, alpha: 1)
    static let electricBlue = SKColor(red: 0.0, green: 0.4, blue: 1.0, alpha: 1)
    static let neonPurple = SKColor(red: 0.48, green: 0.25, blue: 0.95, alpha: 1)
    static let lilac = SKColor(red: 0.71, green: 0.37, blue: 0.90, alpha: 1)
    static let neonPink = SKColor(red: 1.0, green: 0.20, blue: 0.40, alpha: 1)
    static let holeBlack = SKColor(red: 0.03, green: 0.035, blue: 0.047, alpha: 1)

    static func makeBall(radius: CGFloat) -> SKShapeNode {
        let ball = SKShapeNode(circleOfRadius: radius)
        ball.fillColor = electricBlue
        ball.strokeColor = cyan
        ball.lineWidth = 2.5
        ball.glowWidth = 8
        ball.zPosition = 2

        let glow = SKShapeNode(circleOfRadius: radius * 1.35)
        glow.fillColor = cyan.withAlphaComponent(0.18)
        glow.strokeColor = .clear
        glow.zPosition = -1
        ball.addChild(glow)

        let shine = SKShapeNode(circleOfRadius: radius * 0.32)
        shine.fillColor = SKColor(white: 1, alpha: 0.7)
        shine.strokeColor = .clear
        shine.position = CGPoint(x: -radius * 0.28, y: radius * 0.28)
        ball.addChild(shine)

        return ball
    }

    static func makeTarget(radius: CGFloat) -> SKShapeNode {
        let root = SKShapeNode(circleOfRadius: radius)
        root.fillColor = holeBlack
        root.strokeColor = neonPurple.withAlphaComponent(0.85)
        root.lineWidth = 2.5
        root.glowWidth = 4
        root.zPosition = 1

        let hole = SKShapeNode(circleOfRadius: max(radius * 0.62, 8))
        hole.fillColor = SKColor(red: 0.02, green: 0.02, blue: 0.04, alpha: 1)
        hole.strokeColor = lilac.withAlphaComponent(0.35)
        hole.lineWidth = 1.5
        root.addChild(hole)

        let ringsRoot = SKNode()
        ringsRoot.zPosition = 0
        root.addChild(ringsRoot)

        let rings: [(CGFloat, CGFloat)] = [
            (1.18, 0.7),
            (1.38, 0.5),
            (1.58, 0.35),
        ]
        for (factor, alpha) in rings {
            let ring = SKShapeNode(circleOfRadius: radius * factor)
            ring.fillColor = .clear
            ring.strokeColor = neonPurple.withAlphaComponent(alpha)
            ring.lineWidth = 1.4
            ring.glowWidth = 1.5
            ringsRoot.addChild(ring)
        }

        let particleColors: [SKColor] = [
            .white,
            cyan,
            neonPink,
            lilac,
        ]
        let orbitRadius = radius * 1.38
        for i in 0..<6 {
            let angle = CGFloat(i) / 6 * (.pi * 2)
            let speck = SKShapeNode(circleOfRadius: max(radius * 0.07, 2.2))
            speck.fillColor = particleColors[i % particleColors.count]
            speck.strokeColor = .clear
            speck.glowWidth = 2
            speck.position = CGPoint(
                x: cos(angle) * orbitRadius,
                y: sin(angle) * orbitRadius
            )
            ringsRoot.addChild(speck)
        }

        let spin = SKAction.repeatForever(.rotate(byAngle: .pi * 2, duration: 14))
        ringsRoot.run(spin, withKey: "orbitSpin")

        return root
    }

    static func makeObstacle(size: CGSize) -> SKShapeNode {
        let corner = min(size.width, size.height) * 0.28 + 4
        let block = SKShapeNode(rectOf: size, cornerRadius: corner)
        block.fillColor = SKColor(red: 0.08, green: 0.09, blue: 0.18, alpha: 0.82)
        block.strokeColor = lilac
        block.lineWidth = 2
        block.glowWidth = 3
        block.zPosition = 3

        let inset = SKShapeNode(
            rectOf: CGSize(width: max(size.width - 6, 4), height: max(size.height - 6, 4)),
            cornerRadius: max(corner - 2, 2)
        )
        inset.fillColor = neonPurple.withAlphaComponent(0.12)
        inset.strokeColor = cyan.withAlphaComponent(0.25)
        inset.lineWidth = 1
        block.addChild(inset)

        return block
    }
}

struct CosmicGlassCard: ViewModifier {
    var cornerRadius: CGFloat = 22
    var stroke: Color = CosmicTheme.neonPurple.opacity(0.55)

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial.opacity(0.35), in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .background(
                Color.white.opacity(0.06),
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(stroke, lineWidth: 1.5)
            }
    }
}

extension View {
    func cosmicGlass(cornerRadius: CGFloat = 22, stroke: Color = CosmicTheme.neonPurple.opacity(0.55)) -> some View {
        modifier(CosmicGlassCard(cornerRadius: cornerRadius, stroke: stroke))
    }
}
