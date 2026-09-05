import CoreGraphics

enum LevelLayout {
    static let designWidth: CGFloat = 390

    static func scale(for size: CGSize) -> CGFloat {
        max(size.width / designWidth, 0.75)
    }

    static func point(x: Double, y: Double, in size: CGSize) -> CGPoint {
        CGPoint(x: CGFloat(x) * size.width, y: CGFloat(y) * size.height)
    }

    static func obstacleSize(width: Double, height: Double, in size: CGSize) -> CGSize {
        let s = scale(for: size)
        return CGSize(width: CGFloat(width) * s, height: CGFloat(height) * s)
    }
}
