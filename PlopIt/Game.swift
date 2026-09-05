import SpriteKit
import SwiftUI

@Observable
final class GameController {
    private(set) var throwsRemaining = 0
    private(set) var throwsUsed = 0
    private(set) var isEnded = false
    private(set) var didWin = false
    private(set) var levelPayout = 50

    var isMenuOpen = false

    private(set) var levelScore = 0
    private let missPenalty = 5

    var canThrow: Bool {
        !isEnded && !isMenuOpen && throwsRemaining > 0
    }

    func prepare(for level: Level) {
        throwsUsed = 0
        throwsRemaining = level.maxThrows
        isEnded = false
        didWin = false
        levelPayout = level.basePoints
        levelScore = 0
    }

    func revertLevelScore(using repository: LevelRepository) {
        if levelScore != 0 {
            repository.addToTotalScore(-levelScore)
        }
        levelScore = 0
    }

    /// Resume after a fail by granting bonus throws (rewarded ad).
    func grantExtraThrows(_ count: Int) {
        guard isEnded, !didWin else { return }
        throwsRemaining += count
        isEnded = false
    }

    func registerThrow() {
        guard canThrow else { return }
        throwsUsed += 1
        throwsRemaining -= 1
    }

    func resolveShot(isInside: Bool, level: Level, scene: GameScene, repository: LevelRepository) {
        guard !isEnded else { return }

        if isInside {
            if !level.completed {
                applyScore(levelPayout, repository: repository)
            }
            didWin = true
            isEnded = true
            repository.markCompleted(levelId: level.id, throwsUsed: throwsUsed)
            return
        }

        levelPayout = max(0, levelPayout - missPenalty)

        if throwsRemaining == 0 {
            isEnded = true
            return
        }

        if !level.rethrowFromRest {
            scene.resetBallToStart()
        }
    }

    private func applyScore(_ points: Int, repository: LevelRepository) {
        levelScore += points
        repository.addToTotalScore(points)
    }
}

struct GameContentView: View {
    let initialLevelId: Int

    @Environment(LevelRepository.self) private var levelRepo
    @Environment(RouteViewModel.self) private var routeView

    @State private var levelId: Int
    @State private var gameScene = GameScene()
    @State private var controller = GameController()
    @State private var isConfigured = false
    @State private var isMenuVisible = false
    @State private var showEndPanel = false
    @State private var isAwaitingEndAd = false
    @AppStorage("plopit.hasSeenThrowHint") private var hasSeenThrowHint = false
    @State private var showThrowHint = false

    init(levelId: Int) {
        self.initialLevelId = levelId
        _levelId = State(initialValue: levelId)
    }

    private var level: Level? {
        levelRepo.level(id: levelId)
    }

    private var canGoNext: Bool {
        controller.didWin || (level?.completed ?? false)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                CosmicTheme.screenBackground

                SpriteView(scene: gameScene, options: [.allowsTransparency])
                    .onAppear {
                        configureIfNeeded(size: geometry.size)
                    }
                    .onChange(of: geometry.size) { _, newSize in
                        configureIfNeeded(size: newSize)
                    }
                    .padding(.bottom, 60)

                VStack {
                    Spacer()
                    if controller.isEnded && showEndPanel {
                        endButtons
                    }
                    Spacer()
                    hud
                }

                if showThrowHint && !controller.isEnded && !isMenuVisible {
                    ThrowHintOverlay()
                        .allowsHitTesting(false)
                        .transition(.opacity)
                }

                if isMenuVisible {
                    pauseMenu
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            if !hasSeenThrowHint {
                showThrowHint = true
            }
        }
        .onChange(of: controller.throwsUsed) { _, used in
            guard used > 0, showThrowHint else { return }
            withAnimation(.easeOut(duration: 0.35)) {
                showThrowHint = false
            }
            hasSeenThrowHint = true
        }
        .onChange(of: controller.isEnded) { _, ended in
            if ended {
                showEndPanel = false
                isAwaitingEndAd = true
                AdsManager.shared.showEndOfGameAdIfNeeded {
                    isAwaitingEndAd = false
                    withAnimation(.easeOut(duration: 0.25)) {
                        showEndPanel = true
                    }
                }
            } else {
                showEndPanel = false
            }
        }
    }

    private var hud: some View {
        HStack(spacing: 8) {
            Button {
                showMenu()
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.title3.weight(.black))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(CosmicTheme.secondaryGradient, in: Circle())
                    .overlay(Circle().stroke(CosmicTheme.lilac.opacity(0.7), lineWidth: 1.5))
                    .shadow(color: CosmicTheme.neonPurple.opacity(0.45), radius: 8, y: 0)
            }
            .buttonStyle(ShrinkButtonStyle())

            hudChip("L\(levelId)", tint: CosmicTheme.cyan)
            Spacer(minLength: 4)
            if !controller.isEnded {
                hudChip("\(controller.throwsRemaining)", icon: "arrow.up.circle.fill", tint: CosmicTheme.cyan)
            }
        }
        .font(.system(.headline, design: .rounded).weight(.heavy))
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .cosmicGlass(cornerRadius: 22, stroke: CosmicTheme.neonPurple.opacity(0.5))
        .padding(.horizontal, 14)
        .padding(.bottom, 8)
        .shadow(color: CosmicTheme.cyan.opacity(0.12), radius: 12, y: 4)
    }

    private func hudChip(_ text: String, icon: String? = nil, tint: Color) -> some View {
        HStack(spacing: 4) {
            if let icon {
                Image(systemName: icon)
                    .foregroundStyle(tint)
            }
            Text(text)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Color.white.opacity(0.08), in: Capsule())
        .overlay(Capsule().stroke(tint.opacity(0.35), lineWidth: 1))
    }

    private var pauseMenu: some View {
        ZStack {
            Color.black.opacity(0.62)
                .ignoresSafeArea()
                .onTapGesture {
                    hideMenu()
                }

            VStack(spacing: 18) {
                Text("Menu")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(CosmicTheme.titleGradient)

                gameActionButton(
                    title: "Restart",
                    style: .primary
                ) {
                    hideMenu()
                    restart()
                }

                gameActionButton(
                    title: "Home",
                    style: .secondary
                ) {
                    hideMenu()
                    routeView.popToRoot()
                }
            }
            .padding(26)
            .frame(maxWidth: 300)
            .cosmicGlass(cornerRadius: 28, stroke: CosmicTheme.cyan.opacity(0.45))
            .shadow(color: CosmicTheme.neonPurple.opacity(0.35), radius: 24, y: 10)
        }
    }

    private func showMenu() {
        isMenuVisible = true
        controller.isMenuOpen = true
    }

    private func hideMenu() {
        isMenuVisible = false
        controller.isMenuOpen = false
    }

    private var endButtons: some View {
        VStack(spacing: 16) {
            Text(controller.didWin ? "Plop!" : "Try again")
                .font(.system(size: 36, weight: .black, design: .rounded))
                .foregroundStyle(CosmicTheme.titleGradient)
                .shadow(color: CosmicTheme.cyan.opacity(0.45), radius: 10, y: 0)

            Text("\(controller.levelScore) pts")
                .font(.system(.title, design: .rounded).weight(.black))
                .foregroundStyle(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.08), in: Capsule())
                .overlay(Capsule().stroke(CosmicTheme.lilac.opacity(0.55), lineWidth: 1.5))

            if !controller.didWin {
                rewardedContinueButton
            }

            HStack(spacing: 12) {
                gameActionButton(title: "Restart", style: .primary) {
                    restart()
                }

                gameActionButton(title: "Next", style: .secondary, enabled: canGoNext) {
                    goToNext()
                }
            }
        }
        .padding(22)
        .cosmicGlass(cornerRadius: 28, stroke: CosmicTheme.cyan.opacity(0.4))
        .shadow(color: CosmicTheme.neonPurple.opacity(0.3), radius: 18, y: 8)
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }

    private var rewardedContinueButton: some View {
        Button {
            watchAdForExtraThrows()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "play.rectangle.fill")
                    .font(.title3.weight(.bold))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Watch Rewarded Ad")
                        .font(.system(.headline, design: .rounded).weight(.black))
                    Text("+\(AdMobConfig.continueThrowBonus) throws")
                        .font(.system(.caption, design: .rounded).weight(.bold))
                        .opacity(0.9)
                }
                Spacer(minLength: 0)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(CosmicTheme.playGradient)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.35), lineWidth: 1.5)
            }
            .shadow(color: CosmicTheme.cyan.opacity(0.45), radius: 12, y: 0)
        }
        .buttonStyle(ShrinkButtonStyle())
    }

    private enum ActionStyle {
        case primary, secondary, ghost
    }

    private func gameActionButton(
        title: String,
        style: ActionStyle,
        enabled: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(.title3, design: .rounded).weight(.black))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background {
                    if !enabled {
                        Color.white.opacity(0.08)
                    } else {
                        switch style {
                        case .primary:
                            CosmicTheme.playGradient
                        case .secondary:
                            CosmicTheme.secondaryGradient
                        case .ghost:
                            Color.white.opacity(0.08)
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(
                            enabled
                                ? (style == .ghost ? CosmicTheme.neonPurple.opacity(0.55) : Color.white.opacity(0.35))
                                : Color.white.opacity(0.12),
                            lineWidth: 1.5
                        )
                }
                .shadow(
                    color: enabled && style == .primary ? CosmicTheme.cyan.opacity(0.4) : .clear,
                    radius: 10,
                    y: 0
                )
        }
        .buttonStyle(ShrinkButtonStyle())
        .disabled(!enabled)
    }

    private func configureIfNeeded(size: CGSize) {
        guard !isConfigured, size.width > 1, size.height > 1, let level else { return }
        bindScene()
        startLevel(level, size: size)
        isConfigured = true
    }

    private func bindScene() {
        gameScene.canAcceptThrow = { [controller] in
            controller.canThrow
        }
        gameScene.onThrow = { [controller] in
            controller.registerThrow()
        }
        gameScene.onShotResolved = { [controller, levelRepo, weak scene = gameScene] isInside in
            guard let scene, let level = scene.activeLevel else { return }
            controller.resolveShot(
                isInside: isInside,
                level: level,
                scene: scene,
                repository: levelRepo
            )
            scene.updateScoreHUD(
                totalScore: levelRepo.totalScore,
                levelPayout: controller.levelPayout,
                showPayout: !controller.isEnded || controller.didWin
            )
        }
    }

    private func startLevel(_ level: Level, size: CGSize) {
        bindScene()
        controller.prepare(for: level)
        gameScene.configure(with: level, size: size)
        gameScene.updateScoreHUD(
            totalScore: levelRepo.totalScore,
            levelPayout: controller.levelPayout,
            showPayout: true
        )
    }

    private func restart() {
        guard let level, gameScene.size.width > 1 else { return }
        controller.revertLevelScore(using: levelRepo)
        startLevel(level, size: gameScene.size)
    }

    private func watchAdForExtraThrows() {
        isAwaitingEndAd = true
        AdsManager.shared.showRewardedAd { earned in
            defer { isAwaitingEndAd = false }
            guard earned else { return }

            controller.grantExtraThrows(AdMobConfig.continueThrowBonus)
            showEndPanel = false
            gameScene.resetBallToStart()
            gameScene.updateScoreHUD(
                totalScore: levelRepo.totalScore,
                levelPayout: controller.levelPayout,
                showPayout: true
            )
        }
    }

    private func goToNext() {
        guard canGoNext else { return }
        let nextId = levelId + 1
        if let nextLevel = levelRepo.level(id: nextId) {
            levelId = nextId
            startLevel(nextLevel, size: gameScene.size)
        } else {
            routeView.popToRoot()
        }
    }
}

private struct ThrowHintOverlay: View {
    @State private var pullProgress = false

    var body: some View {
        VStack(spacing: 18) {
            Spacer()

            ZStack {
                // Fading aim dots (throw direction = opposite of pull)
                ForEach(0..<5, id: \.self) { index in
                    Circle()
                        .fill(CosmicTheme.cyan.opacity(0.85 - Double(index) * 0.15))
                        .frame(width: 10 - CGFloat(index), height: 10 - CGFloat(index))
                        .offset(y: -28 - CGFloat(index) * 18)
                        .opacity(pullProgress ? 1 : 0.35)
                }

                // Pull finger
                ZStack {
                    Circle()
                        .stroke(CosmicTheme.cyan.opacity(0.45), lineWidth: 2)
                        .frame(width: 64, height: 64)
                        .scaleEffect(pullProgress ? 1.15 : 0.9)

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [CosmicTheme.cyan, CosmicTheme.electricBlue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 42, height: 42)
                        .shadow(color: CosmicTheme.cyan.opacity(0.55), radius: 12, y: 0)
                        .overlay {
                            Image(systemName: "hand.draw.fill")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(.white)
                        }
                }
                .offset(y: pullProgress ? 56 : 0)
            }
            .frame(height: 170)

            VStack(spacing: 6) {
                Text("Pull anywhere")
                    .font(.system(.title2, design: .rounded).weight(.black))
                    .foregroundStyle(CosmicTheme.titleGradient)
                Text("Drag back, then release to launch")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(.white.opacity(0.75))
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 14)
            .cosmicGlass(cornerRadius: 20, stroke: CosmicTheme.cyan.opacity(0.45))
            .shadow(color: CosmicTheme.cyan.opacity(0.2), radius: 16, y: 0)
            .offset(y: -200)

            Spacer()
                .frame(height: 110)
        }
        .padding(.horizontal, 24)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.15).repeatForever(autoreverses: true)) {
                pullProgress = true
            }
        }
    }
}

class GameScene: SKScene {
    var targetNode: SKShapeNode!
    var ballNode: SKShapeNode!

    var touchStartPoint: CGPoint = .zero
    var targetRadius: CGFloat = 0
    var ballRadius: CGFloat = 14
    private var startPosition: CGPoint = .zero
    private var shotInProgress = false
    private var currentLevel: Level?

    var hasActiveShot: Bool { shotInProgress }
    var activeLevel: Level? { currentLevel }

    var canAcceptThrow: () -> Bool = { true }
    var onThrow: (() -> Void)?
    var onShotResolved: ((Bool) -> Void)?
    private var isTrackingThrow = false
    private var aimArrow: SKNode?
    private var lastAimTouchPoint: CGPoint?

    private var scoreHUDRoot: SKNode?
    private var totalScoreLabel: SKLabelNode?
    private var payoutLabel: SKLabelNode?
    private var payoutChip: SKNode?
    private var cachedTotalScore = 0
    private var cachedLevelPayout = 0
    private var cachedShowPayout = true

    override func didMove(to view: SKView) {
        physicsWorld.gravity = .zero
        scaleMode = .resizeFill
        syncSize(to: view.bounds.size)
        if currentLevel != nil, children.isEmpty {
            setupScene()
        }
    }

    override func didChangeSize(_ oldSize: CGSize) {
        let sizeChanged =
            abs(oldSize.width - size.width) > 1
            || abs(oldSize.height - size.height) > 1
        guard currentLevel != nil, sizeChanged else { return }
        if shotInProgress {
            refreshBorder()
        } else {
            setupScene()
        }
    }

    func configure(with level: Level, size: CGSize) {
        currentLevel = level
        scaleMode = .resizeFill
        syncSize(to: size)
        setupScene()
    }

    private func syncSize(to newSize: CGSize) {
        guard newSize.width > 1, newSize.height > 1 else { return }
        if abs(size.width - newSize.width) > 1 || abs(size.height - newSize.height) > 1 {
            self.size = newSize
        }
    }

    func resetBallToStart() {
        guard let body = ballNode.physicsBody else { return }
        body.velocity = .zero
        body.angularVelocity = 0
        ballNode.position = startPosition
    }

    private func refreshBorder() {
        let border = SKPhysicsBody(edgeLoopFrom: frame)
        border.categoryBitMask = PhysicsCategory.wall
        border.collisionBitMask = PhysicsCategory.ball
        physicsBody = border
    }
}

private struct PhysicsCategory {
    static let none: UInt32 = 0
    static let ball: UInt32 = 0b1
    static let block: UInt32 = 0b10
    static let wall: UInt32 = 0b100
}

extension GameScene {
    func setupScene() {
        guard let level = currentLevel else { return }

        removeAllChildren()
        shotInProgress = false
        PlayfieldBackground.add(to: self)
        refreshBorder()

        let scale = LevelLayout.scale(for: size)
        ballRadius = 14 * scale
        targetRadius = CGFloat(level.target.radius) * scale

        targetNode = SKCosmic.makeTarget(radius: targetRadius)
        targetNode.position = LevelLayout.point(x: level.target.x, y: level.target.y, in: size)
        addChild(targetNode)

        startPosition = LevelLayout.point(x: level.ballStart.x, y: level.ballStart.y, in: size)
        ballNode = SKCosmic.makeBall(radius: ballRadius)
        ballNode.position = startPosition

        let body = SKPhysicsBody(circleOfRadius: ballRadius)
        body.isDynamic = true
        body.linearDamping = 1.2
        body.allowsRotation = false
        body.categoryBitMask = PhysicsCategory.ball
        body.collisionBitMask = PhysicsCategory.block | PhysicsCategory.wall
        ballNode.physicsBody = body
        addChild(ballNode)

        for obstacle in level.obstacles {
            addObstacle(obstacle, in: size)
        }

        addAimArrow()
        addScoreHUD()
        updateScoreHUD(
            totalScore: cachedTotalScore,
            levelPayout: cachedLevelPayout,
            showPayout: cachedShowPayout
        )
    }

    func updateScoreHUD(totalScore: Int, levelPayout: Int, showPayout: Bool) {
        cachedTotalScore = totalScore
        cachedLevelPayout = levelPayout
        cachedShowPayout = showPayout

        if scoreHUDRoot == nil || scoreHUDRoot?.parent == nil {
            addScoreHUD()
        }

        totalScoreLabel?.text = "SCORE  \(totalScore)"
        payoutLabel?.text = "+\(levelPayout)"
        payoutChip?.isHidden = !showPayout
        payoutChip?.alpha = levelPayout > 0 ? 1 : 0.45
    }

    private func addScoreHUD() {
        scoreHUDRoot?.removeFromParent()

        let root = SKNode()
        root.zPosition = 100
        root.name = "scoreHUD"

        let topY = size.height - 58

        let totalChip = makeHUDChip(
            width: 148,
            stroke: SKCosmic.lilac.withAlphaComponent(0.7)
        )
        totalChip.position = CGPoint(x: 20 + 74, y: topY)

        let totalLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        totalLabel.fontSize = 15
        totalLabel.fontColor = .white
        totalLabel.verticalAlignmentMode = .center
        totalLabel.horizontalAlignmentMode = .center
        totalLabel.text = "SCORE  \(cachedTotalScore)"
        totalChip.addChild(totalLabel)
        totalScoreLabel = totalLabel

        let payout = makeHUDChip(
            width: 92,
            stroke: SKCosmic.cyan.withAlphaComponent(0.75)
        )
        payout.position = CGPoint(x: size.width - 20 - 46, y: topY)

        let payoutText = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        payoutText.fontSize = 16
        payoutText.fontColor = SKCosmic.cyan
        payoutText.verticalAlignmentMode = .center
        payoutText.horizontalAlignmentMode = .center
        payoutText.text = "+\(cachedLevelPayout)"
        payout.addChild(payoutText)
        payoutLabel = payoutText
        payoutChip = payout
        payout.isHidden = !cachedShowPayout

        root.addChild(totalChip)
        root.addChild(payout)
        addChild(root)
        scoreHUDRoot = root
    }

    private func makeHUDChip(width: CGFloat, stroke: SKColor) -> SKShapeNode {
        let chip = SKShapeNode(
            rectOf: CGSize(width: width, height: 34),
            cornerRadius: 17
        )
        chip.fillColor = SKColor(white: 1, alpha: 0.1)
        chip.strokeColor = stroke
        chip.lineWidth = 1.5
        chip.glowWidth = 2
        return chip
    }

    private func addAimArrow() {
        let arrow = SKNode()
        arrow.zPosition = 20
        arrow.isHidden = true
        arrow.name = "aimArrow"

        for i in 0..<7 {
            let t = CGFloat(i) / 6
            let radius = max(3.2 - t * 1.8, 1.4)
            let dot = SKShapeNode(circleOfRadius: radius)
            dot.fillColor = SKCosmic.cyan.withAlphaComponent(1.0 - t * 0.82)
            dot.strokeColor = .clear
            dot.glowWidth = 2
            dot.position = CGPoint(x: 22 + CGFloat(i) * 14, y: 0)
            dot.name = "dot-\(i)"
            arrow.addChild(dot)
        }

        addChild(arrow)
        aimArrow = arrow
    }

    private func addObstacle(_ config: ObstacleConfig, in sceneSize: CGSize) {
        let blockSize = LevelLayout.obstacleSize(
            width: config.width,
            height: config.height,
            in: sceneSize
        )
        let block = SKCosmic.makeObstacle(size: blockSize)
        block.position = LevelLayout.point(x: config.x, y: config.y, in: sceneSize)
        block.zRotation = CGFloat(config.rotation) * .pi / 180

        let blockBody = SKPhysicsBody(rectangleOf: blockSize)
        blockBody.isDynamic = false
        blockBody.restitution = 0.8
        blockBody.categoryBitMask = PhysicsCategory.block
        blockBody.collisionBitMask = PhysicsCategory.ball
        block.physicsBody = blockBody
        addChild(block)
    }
}

extension GameScene {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard canAcceptThrow(), let touch = touches.first else { return }
        isTrackingThrow = true
        touchStartPoint = touch.location(in: self)
        lastAimTouchPoint = touchStartPoint
        hideAimArrow()
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isTrackingThrow, canAcceptThrow(), let touch = touches.first else { return }
        let point = touch.location(in: self)
        lastAimTouchPoint = point
        updateAimArrow(to: point)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        defer {
            isTrackingThrow = false
            lastAimTouchPoint = nil
            hideAimArrow()
        }
        guard isTrackingThrow, canAcceptThrow(),
              let touch = touches.first, let body = ballNode.physicsBody else { return }
        let touchEndPoint = touch.location(in: self)

        let dx = (touchStartPoint.x - touchEndPoint.x) * 1.5
        let dy = (touchStartPoint.y - touchEndPoint.y) * 1.5
        guard hypot(dx, dy) > 1 else { return }

        body.applyImpulse(CGVector(dx: dx, dy: dy))
        shotInProgress = true
        onThrow?()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        isTrackingThrow = false
        lastAimTouchPoint = nil
        hideAimArrow()
    }

    private func updateAimArrow(to touchPoint: CGPoint) {
        guard let arrow = aimArrow, let ball = ballNode else { return }
        let throwDx = touchStartPoint.x - touchPoint.x
        let throwDy = touchStartPoint.y - touchPoint.y
        let pull = hypot(throwDx, throwDy)
        guard pull > 1 else {
            arrow.isHidden = true
            return
        }

        arrow.position = ball.position
        arrow.zRotation = atan2(throwDy, throwDx)
        let scale = min(max(pull / 90, 0.5), 2.0)
        arrow.setScale(scale)
        arrow.isHidden = false
    }

    private func hideAimArrow() {
        aimArrow?.isHidden = true
    }
}

extension GameScene {
    override func update(_ currentTime: TimeInterval) {
        if isTrackingThrow, let aimPoint = lastAimTouchPoint, canAcceptThrow() {
            updateAimArrow(to: aimPoint)
        }

        guard shotInProgress, let body = ballNode.physicsBody else { return }

        let distance = hypot(
            ballNode.position.x - targetNode.position.x,
            ballNode.position.y - targetNode.position.y
        )

        if distance <= targetRadius {
            body.velocity = .zero
            body.angularVelocity = 0
            shotInProgress = false
            isTrackingThrow = false
            lastAimTouchPoint = nil
            hideAimArrow()
            onShotResolved?(true)
            return
        }

        let speed = hypot(body.velocity.dx, body.velocity.dy)
        if speed < 1.5 {
            body.velocity = .zero
            body.angularVelocity = 0
            shotInProgress = false
            onShotResolved?(false)
        }
    }
}
