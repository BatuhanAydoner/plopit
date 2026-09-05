import SpriteKit
import SwiftUI
import UIKit

@Observable
final class LevelDraft {
    var ballX = 0.5
    var ballY = 0.13
    var targetX = 0.5
    var targetY = 0.72
    var targetRadius = 52.0
    var obstacles: [ObstacleConfig] = []
    var selected: EditorSelection = .target
    var copied = false

    var jsonText: String {
        let level = Level(
            id: 0,
            maxThrows: 20,
            basePoints: 50,
            rethrowFromRest: true,
            ballStart: NormalizedPoint(x: round2(ballX), y: round2(ballY)),
            target: TargetConfig(
                radius: round1(targetRadius),
                x: round2(targetX),
                y: round2(targetY)
            ),
            obstacles: obstacles.map { obs in
                ObstacleConfig(
                    width: round1(obs.width),
                    height: round1(obs.height),
                    x: round2(obs.x),
                    y: round2(obs.y),
                    rotation: round1(obs.rotation)
                )
            }
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(level),
              let text = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return text
    }

    func addObstacle(vertical: Bool) {
        let obs = ObstacleConfig(
            width: vertical ? 14 : 150,
            height: vertical ? 120 : 14,
            x: 0.5,
            y: 0.42,
            rotation: 0
        )
        obstacles.append(obs)
        selected = .obstacle(obstacles.count - 1)
    }

    func deleteSelected() {
        guard case .obstacle(let index) = selected, obstacles.indices.contains(index) else { return }
        obstacles.remove(at: index)
        selected = obstacles.isEmpty ? .target : .obstacle(min(index, obstacles.count - 1))
    }

    func rotateSelected(_ degrees: Double) {
        guard case .obstacle(let index) = selected, obstacles.indices.contains(index) else { return }
        let obs = obstacles[index]
        obstacles[index] = ObstacleConfig(
            width: obs.width,
            height: obs.height,
            x: obs.x,
            y: obs.y,
            rotation: obs.rotation + degrees
        )
    }

    func copyJSON() {
        UIPasteboard.general.string = jsonText
        copied = true
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            copied = false
        }
    }

    private func round2(_ value: Double) -> Double { (value * 1000).rounded() / 1000 }
    private func round1(_ value: Double) -> Double { (value * 10).rounded() / 10 }
}

enum EditorSelection: Equatable {
    case none
    case ball
    case target
    case obstacle(Int)
}

struct LevelEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft = LevelDraft()
    @State private var scene = LevelEditorScene()
    @State private var isToolbarOpen = false

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                CosmicTheme.screenBackground

                SpriteView(scene: scene, options: [.allowsTransparency])
                    .onAppear { configure(size: geometry.size) }
                    .onChange(of: geometry.size) { _, newSize in
                        configure(size: newSize)
                    }
                    .padding(.bottom, 60)

                hud

                if isToolbarOpen {
                    toolbarPanel
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .onChange(of: draft.selected) { _, _ in
            scene.refreshSelection()
        }
        .onChange(of: draft.targetRadius) { _, _ in
            scene.reloadTarget()
        }
    }

    private var hud: some View {
        HStack(spacing: 8) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.black))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(CosmicTheme.dangerGradient, in: Circle())
                    .overlay(Circle().stroke(CosmicTheme.neonPink.opacity(0.7), lineWidth: 1.5))
            }
            .buttonStyle(ShrinkButtonStyle())

            hudChip("Design", tint: CosmicTheme.cyan)

            Spacer(minLength: 4)

            hudChip(selectionSummary, tint: CosmicTheme.lilac)

            Button {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                    isToolbarOpen = true
                }
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.title3.weight(.black))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(CosmicTheme.secondaryGradient, in: Circle())
                    .overlay(Circle().stroke(CosmicTheme.lilac.opacity(0.7), lineWidth: 1.5))
            }
            .buttonStyle(ShrinkButtonStyle())
        }
        .font(.system(.headline, design: .rounded).weight(.heavy))
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .cosmicGlass(cornerRadius: 22, stroke: CosmicTheme.neonPurple.opacity(0.5))
        .padding(.horizontal, 14)
        .padding(.bottom, 8)
        .shadow(color: CosmicTheme.cyan.opacity(0.12), radius: 12, y: 4)
    }

    private func hudChip(_ text: String, tint: Color) -> some View {
        Text(text)
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(.black.opacity(0.18), in: Capsule())
            .overlay {
                Capsule().stroke(tint.opacity(0.35), lineWidth: 1)
            }
    }

    private var selectionSummary: String {
        switch draft.selected {
        case .none: return "—"
        case .ball: return "Ball"
        case .target: return "Target"
        case .obstacle(let i): return "E\(i + 1)"
        }
    }

    private var toolbarPanel: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.62)
                .ignoresSafeArea()
                .onTapGesture {
                    closeToolbar()
                }

            VStack(spacing: 14) {
                HStack {
                    Text("Tools")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(CosmicTheme.titleGradient)
                    Spacer()
                    Button {
                        closeToolbar()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.headline.weight(.black))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.12), in: Circle())
                            .overlay(Circle().stroke(CosmicTheme.neonPink.opacity(0.6), lineWidth: 1))
                    }
                    .buttonStyle(ShrinkButtonStyle())
                }

                inspector

                toolbar

                Button {
                    draft.copyJSON()
                } label: {
                    Text(draft.copied ? "Copied ✓" : "Copy JSON")
                        .font(.system(.headline, design: .rounded).weight(.black))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(CosmicTheme.playGradient, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: CosmicTheme.cyan.opacity(0.4), radius: 10, y: 0)
                }
                .buttonStyle(ShrinkButtonStyle())
            }
            .padding(20)
            .padding(.bottom, 8)
            .cosmicGlass(cornerRadius: 28, stroke: CosmicTheme.cyan.opacity(0.4))
            .shadow(color: CosmicTheme.neonPurple.opacity(0.3), radius: 20, y: 10)
            .padding(.horizontal, 14)
            .padding(.bottom, 72)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private func closeToolbar() {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
            isToolbarOpen = false
        }
    }

    private var inspector: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(selectionTitle)
                .font(.system(.headline, design: .rounded).weight(.black))
                .foregroundStyle(.white)
            Text(selectionCoords)
                .font(.system(.caption, design: .monospaced).weight(.bold))
                .foregroundStyle(.white.opacity(0.9))
            if draft.selected == .target {
                HStack {
                    Text("Radius")
                    Slider(
                        value: Binding(
                            get: { draft.targetRadius },
                            set: { draft.targetRadius = $0 }
                        ),
                        in: 26...80,
                        step: 1
                    )
                }
                .font(.system(.caption, design: .rounded).weight(.bold))
                .foregroundStyle(.white)
            }
            if !draft.obstacles.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(draft.obstacles.enumerated()), id: \.offset) { index, obs in
                            Text(String(format: "E%d  x: %.3f  y: %.3f  r: %.0f", index + 1, obs.x, obs.y, obs.rotation))
                                .font(.system(size: 11, design: .monospaced).weight(.bold))
                                .foregroundStyle(.white.opacity(0.85))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .frame(maxHeight: 72)
                .scrollIndicators(.visible)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cosmicGlass(cornerRadius: 18, stroke: CosmicTheme.neonPurple.opacity(0.4))
    }

    private var toolbar: some View {
        HStack(spacing: 8) {
            toolButton("Bar") { draft.addObstacle(vertical: false); scene.reloadObstacles() }
            toolButton("Post") { draft.addObstacle(vertical: true); scene.reloadObstacles() }
            toolButton("Rotate") {
                draft.rotateSelected(15)
                scene.reloadObstacles()
            }
            toolButton("Delete", destructive: true) {
                draft.deleteSelected()
                scene.reloadObstacles()
            }
            .disabled({
                if case .obstacle = draft.selected { return false }
                return true
            }())
            .opacity({
                if case .obstacle = draft.selected { return 1 }
                return 0.4
            }())
        }
    }

    private func toolButton(_ title: String, destructive: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(.subheadline, design: .rounded).weight(.black))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    destructive
                        ? CosmicTheme.dangerGradient
                        : CosmicTheme.secondaryGradient,
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                }
        }
        .buttonStyle(ShrinkButtonStyle())
    }

    private var selectionTitle: String {
        switch draft.selected {
        case .none: return "Select something"
        case .ball: return "Ball"
        case .target: return "Target"
        case .obstacle(let i): return "Obstacle \(i + 1)"
        }
    }

    private var selectionCoords: String {
        switch draft.selected {
        case .none:
            return "Drag the target or an obstacle"
        case .ball:
            return String(format: "x: %.3f   y: %.3f", draft.ballX, draft.ballY)
        case .target:
            return String(format: "x: %.3f   y: %.3f   r: %.1f", draft.targetX, draft.targetY, draft.targetRadius)
        case .obstacle(let i):
            guard draft.obstacles.indices.contains(i) else { return "" }
            let obs = draft.obstacles[i]
            return String(format: "x: %.3f   y: %.3f   rot: %.1f", obs.x, obs.y, obs.rotation)
        }
    }

    private func configure(size: CGSize) {
        guard size.width > 1, size.height > 1 else { return }
        scene.draft = draft
        scene.configure(size: size)
    }
}

class LevelEditorScene: SKScene {
    var draft: LevelDraft?
    private var ballNode: SKShapeNode?
    private var targetNode: SKShapeNode?
    private var obstacleNodes: [SKShapeNode] = []
    private var dragOffset: CGPoint = .zero

    func configure(size: CGSize) {
        self.size = size
        scaleMode = .resizeFill
        rebuild()
    }

    func reloadObstacles() {
        rebuild()
    }

    func reloadTarget() {
        rebuild()
    }

    func refreshSelection() {
        applySelectionStyle()
    }

    private func rebuild() {
        guard let draft else { return }
        removeAllChildren()
        PlayfieldBackground.add(to: self)

        let scale = LevelLayout.scale(for: size)
        let targetRadius = CGFloat(draft.targetRadius) * scale

        let target = SKCosmic.makeTarget(radius: targetRadius)
        target.position = LevelLayout.point(x: draft.targetX, y: draft.targetY, in: size)
        target.name = "target"
        addChild(target)
        targetNode = target

        let ball = SKCosmic.makeBall(radius: 14 * scale)
        ball.position = LevelLayout.point(x: draft.ballX, y: draft.ballY, in: size)
        ball.name = "ball"
        addChild(ball)
        ballNode = ball

        obstacleNodes = []
        for (index, obs) in draft.obstacles.enumerated() {
            let obstacleSize = LevelLayout.obstacleSize(width: obs.width, height: obs.height, in: size)
            let node = SKCosmic.makeObstacle(size: obstacleSize)
            node.position = LevelLayout.point(x: obs.x, y: obs.y, in: size)
            node.zRotation = CGFloat(obs.rotation) * .pi / 180
            node.name = "obstacle-\(index)"
            addChild(node)
            obstacleNodes.append(node)
        }

        applySelectionStyle()
    }

    private func applySelectionStyle() {
        ballNode?.glowWidth = draft?.selected == .ball ? 14 : 8
        ballNode?.lineWidth = draft?.selected == .ball ? 4 : 2.5
        targetNode?.glowWidth = draft?.selected == .target ? 8 : 4
        targetNode?.lineWidth = draft?.selected == .target ? 4 : 2.5
        for (index, node) in obstacleNodes.enumerated() {
            let on = draft?.selected == .obstacle(index)
            node.strokeColor = on ? SKCosmic.cyan : SKCosmic.lilac
            node.glowWidth = on ? 6 : 3
            node.lineWidth = on ? 3 : 2
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let draft else { return }
        let location = touch.location(in: self)
        if let node = nodes(at: location).first(where: { $0.name != nil }) {
            if node.name == "ball" {
                draft.selected = .ball
            } else if node.name == "target" {
                draft.selected = .target
            } else if let name = node.name, name.hasPrefix("obstacle-"),
                      let index = Int(name.dropFirst("obstacle-".count)) {
                draft.selected = .obstacle(index)
            }
            dragOffset = CGPoint(x: node.position.x - location.x, y: node.position.y - location.y)
        }
        applySelectionStyle()
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let draft else { return }
        let location = touch.location(in: self)
        let x = Double((location.x + dragOffset.x) / size.width)
        let y = Double((location.y + dragOffset.y) / size.height)

        switch draft.selected {
        case .ball:
            draft.ballX = x
            draft.ballY = y
            ballNode?.position = LevelLayout.point(x: x, y: y, in: size)
        case .target:
            draft.targetX = x
            draft.targetY = y
            targetNode?.position = LevelLayout.point(x: x, y: y, in: size)
        case .obstacle(let index):
            guard draft.obstacles.indices.contains(index) else { return }
            let obs = draft.obstacles[index]
            draft.obstacles[index] = ObstacleConfig(
                width: obs.width,
                height: obs.height,
                x: x,
                y: y,
                rotation: obs.rotation
            )
            obstacleNodes[safe: index]?.position = LevelLayout.point(x: x, y: y, in: size)
        case .none:
            break
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
