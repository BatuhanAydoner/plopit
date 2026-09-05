import Foundation

struct LevelsDocument: Codable {
    var version: Int
    var levels: [Level]
}

struct Level: Codable, Identifiable, Hashable {
    let id: Int
    let maxThrows: Int
    let basePoints: Int
    let rethrowFromRest: Bool
    let ballStart: NormalizedPoint
    let target: TargetConfig
    let obstacles: [ObstacleConfig]
    var completed: Bool
    var throwsToComplete: Int?

    enum CodingKeys: String, CodingKey {
        case id, maxThrows, basePoints, rethrowFromRest, ballStart, target, obstacles, completed, throwsToComplete
    }

    init(
        id: Int,
        maxThrows: Int,
        basePoints: Int = 50,
        rethrowFromRest: Bool,
        ballStart: NormalizedPoint,
        target: TargetConfig,
        obstacles: [ObstacleConfig],
        completed: Bool = false,
        throwsToComplete: Int? = nil
    ) {
        self.id = id
        self.maxThrows = maxThrows
        self.basePoints = basePoints
        self.rethrowFromRest = rethrowFromRest
        self.ballStart = ballStart
        self.target = target
        self.obstacles = obstacles
        self.completed = completed
        self.throwsToComplete = throwsToComplete
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        maxThrows = try container.decode(Int.self, forKey: .maxThrows)
        rethrowFromRest = try container.decode(Bool.self, forKey: .rethrowFromRest)
        ballStart = try container.decodeIfPresent(NormalizedPoint.self, forKey: .ballStart)
            ?? NormalizedPoint(x: 0.5, y: 0.13)
        target = try container.decode(TargetConfig.self, forKey: .target)
        obstacles = try container.decodeIfPresent([ObstacleConfig].self, forKey: .obstacles) ?? []
        completed = try container.decodeIfPresent(Bool.self, forKey: .completed) ?? false
        throwsToComplete = try container.decodeIfPresent(Int.self, forKey: .throwsToComplete)
        basePoints = try container.decodeIfPresent(Int.self, forKey: .basePoints)
            ?? (50 + (id - 1) * 10)
    }
}

struct NormalizedPoint: Codable, Hashable {
    let x: Double
    let y: Double
}

struct TargetConfig: Codable, Hashable {
    let radius: Double
    let x: Double
    let y: Double
}

struct ObstacleConfig: Codable, Hashable {
    let width: Double
    let height: Double
    let x: Double
    let y: Double
    let rotation: Double

    init(width: Double, height: Double, x: Double, y: Double, rotation: Double = 0) {
        self.width = width
        self.height = height
        self.x = x
        self.y = y
        self.rotation = rotation
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        width = try container.decode(Double.self, forKey: .width)
        height = try container.decode(Double.self, forKey: .height)
        x = try container.decode(Double.self, forKey: .x)
        y = try container.decode(Double.self, forKey: .y)
        rotation = try container.decodeIfPresent(Double.self, forKey: .rotation) ?? 0
    }

    private enum CodingKeys: String, CodingKey {
        case width, height, x, y, rotation
    }
}

struct ProgressDocument: Codable {
    var levels: [String: LevelProgress]
    var totalScore: Int

    init(levels: [String: LevelProgress] = [:], totalScore: Int = 0) {
        self.levels = levels
        self.totalScore = totalScore
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        levels = try container.decodeIfPresent([String: LevelProgress].self, forKey: .levels) ?? [:]
        totalScore = try container.decodeIfPresent(Int.self, forKey: .totalScore) ?? 0
    }

    private enum CodingKeys: String, CodingKey {
        case levels, totalScore
    }
}

struct LevelProgress: Codable, Hashable {
    var completed: Bool
    var throwsToComplete: Int?
}
