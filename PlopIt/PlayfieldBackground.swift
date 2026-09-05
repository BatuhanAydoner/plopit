import SpriteKit

enum PlayfieldBackground {
    static func add(to scene: SKScene) {
        let size = scene.size
        scene.backgroundColor = SKCosmic.obsidian

        addDeepGradient(to: scene, size: size)
        addNebulaOrbs(to: scene, size: size)
        addStarfield(to: scene, size: size)
        addSubtleGrid(to: scene, size: size)
        addRimGlow(to: scene, size: size)
    }

    private static func addDeepGradient(to scene: SKScene, size: CGSize) {
        let layers: [(CGFloat, SKColor, CGFloat)] = [
            (0.88, SKCosmic.deepNavy.withAlphaComponent(0.95), 0.7),
            (0.55, SKCosmic.neonPurple.withAlphaComponent(0.18), 0.5),
            (0.28, SKCosmic.electricBlue.withAlphaComponent(0.12), 0.42),
            (0.08, SKCosmic.obsidian.withAlphaComponent(0.9), 0.35),
        ]

        for (index, layer) in layers.enumerated() {
            let height = size.height * layer.2
            let band = SKShapeNode(
                rectOf: CGSize(width: size.width * 1.3, height: height),
                cornerRadius: height * 0.45
            )
            band.fillColor = layer.1
            band.strokeColor = .clear
            band.position = CGPoint(x: size.width * 0.5, y: size.height * layer.0)
            band.zPosition = -70 + CGFloat(index)
            scene.addChild(band)
        }
    }

    private static func addNebulaOrbs(to scene: SKScene, size: CGSize) {
        let orbs: [(CGFloat, CGFloat, CGFloat, SKColor)] = [
            (0.82, 0.86, 0.38, SKCosmic.cyan.withAlphaComponent(0.14)),
            (0.14, 0.68, 0.28, SKCosmic.neonPurple.withAlphaComponent(0.16)),
            (0.88, 0.24, 0.24, SKCosmic.lilac.withAlphaComponent(0.12)),
            (0.28, 0.22, 0.2, SKCosmic.neonPink.withAlphaComponent(0.08)),
        ]

        for (ox, oy, radiusFactor, color) in orbs {
            let orb = SKShapeNode(circleOfRadius: max(size.width * radiusFactor, 48))
            orb.fillColor = color
            orb.strokeColor = .clear
            orb.position = CGPoint(x: size.width * ox, y: size.height * oy)
            orb.zPosition = -60
            scene.addChild(orb)

            let breathe = SKAction.sequence([
                .scale(to: 1.1, duration: 4.2),
                .scale(to: 1.0, duration: 4.2),
            ])
            orb.run(.repeatForever(breathe))
        }
    }

    private static func addStarfield(to scene: SKScene, size: CGSize) {
        for i in 0..<28 {
            let star = SKShapeNode(circleOfRadius: CGFloat.random(in: 0.8...2.2))
            let tintRoll = i % 5
            switch tintRoll {
            case 0: star.fillColor = SKCosmic.cyan.withAlphaComponent(0.7)
            case 1: star.fillColor = SKCosmic.lilac.withAlphaComponent(0.55)
            case 2: star.fillColor = .white.withAlphaComponent(0.65)
            default: star.fillColor = SKColor(white: 1, alpha: 0.35)
            }
            star.strokeColor = .clear
            star.glowWidth = 1.2
            star.position = CGPoint(
                x: size.width * CGFloat.random(in: 0.04...0.96),
                y: size.height * CGFloat.random(in: 0.06...0.94)
            )
            star.zPosition = -50
            scene.addChild(star)

            let twinkle = SKAction.sequence([
                .wait(forDuration: Double(i) * 0.11),
                .repeatForever(.sequence([
                    .fadeAlpha(to: 0.15, duration: Double.random(in: 1.0...1.8)),
                    .fadeAlpha(to: 0.9, duration: Double.random(in: 1.0...1.8)),
                ])),
            ])
            star.run(twinkle)
        }
    }

    private static func addSubtleGrid(to scene: SKScene, size: CGSize) {
        let spacing = max(size.width / 7, 48)
        let lineColor = SKCosmic.neonPurple.withAlphaComponent(0.05)

        var x: CGFloat = spacing
        while x < size.width {
            let path = CGMutablePath()
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: size.height))
            let line = SKShapeNode(path: path)
            line.strokeColor = lineColor
            line.lineWidth = 1
            line.zPosition = -45
            scene.addChild(line)
            x += spacing
        }

        var y: CGFloat = spacing
        while y < size.height {
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))
            let line = SKShapeNode(path: path)
            line.strokeColor = lineColor
            line.lineWidth = 1
            line.zPosition = -45
            scene.addChild(line)
            y += spacing
        }
    }

    private static func addRimGlow(to scene: SKScene, size: CGSize) {
        let rim = SKShapeNode(rectOf: size)
        rim.fillColor = .clear
        rim.strokeColor = SKCosmic.cyan.withAlphaComponent(0.1)
        rim.lineWidth = max(size.width * 0.045, 16)
        rim.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        rim.zPosition = -20
        scene.addChild(rim)
    }
}
