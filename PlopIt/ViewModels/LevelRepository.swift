import Foundation

@MainActor
@Observable
final class LevelRepository {
    private(set) var levels: [Level] = []
    private(set) var totalScore = 0

    private enum StorageKey {
        static let progress = "plopit.progress"
        static let totalScore = "plopit.totalScore"
    }

    private let defaults = UserDefaults.standard

    init() {
        reload()
    }

    func reload() {
        let hadStoredProgress = defaults.data(forKey: StorageKey.progress) != nil
        let design = Self.loadDesign()
        let progress = loadProgress()
        totalScore = progress.totalScore
        levels = design.map { level in
            var merged = level
            if let saved = progress.levels[String(level.id)] {
                merged.completed = saved.completed
                merged.throwsToComplete = saved.throwsToComplete
            }
            return merged
        }
        if !hadStoredProgress {
            persistProgress()
        }
    }

    func level(id: Int) -> Level? {
        levels.first { $0.id == id }
    }

    func isUnlocked(_ id: Int) -> Bool {
        if id == levels.first?.id { return true }
        return level(id: id - 1)?.completed == true
    }

    func firstPlayableLevelId() -> Int? {
        if let next = levels.first(where: { isUnlocked($0.id) && !$0.completed }) {
            return next.id
        }
        return levels.last?.id
    }

    func addToTotalScore(_ points: Int) {
        totalScore += points
        persistProgress()
    }

    func markCompleted(levelId: Int, throwsUsed: Int) {
        guard let index = levels.firstIndex(where: { $0.id == levelId }) else { return }
        var level = levels[index]

        if level.completed, let best = level.throwsToComplete {
            if throwsUsed < best {
                level.throwsToComplete = throwsUsed
            }
        } else {
            level.completed = true
            level.throwsToComplete = throwsUsed
        }

        levels[index] = level
        persistProgress()
    }

    private func persistProgress() {
        var document = ProgressDocument(levels: [:], totalScore: totalScore)
        for level in levels where level.completed {
            document.levels[String(level.id)] = LevelProgress(
                completed: level.completed,
                throwsToComplete: level.throwsToComplete
            )
        }

        defaults.set(totalScore, forKey: StorageKey.totalScore)
        do {
            let data = try JSONEncoder().encode(document)
            defaults.set(data, forKey: StorageKey.progress)
        } catch {
            assertionFailure("Failed to save progress: \(error)")
        }
        removeLegacyFileIfNeeded()
    }

    private func loadProgress() -> ProgressDocument {
        if let data = defaults.data(forKey: StorageKey.progress),
           let document = try? JSONDecoder().decode(ProgressDocument.self, from: data) {
            return document
        }

        if defaults.object(forKey: StorageKey.totalScore) != nil {
            return ProgressDocument(
                levels: [:],
                totalScore: defaults.integer(forKey: StorageKey.totalScore)
            )
        }

        return loadLegacyFile()
    }

    private func loadLegacyFile() -> ProgressDocument {
        let url = Self.legacyProgressURL
        guard FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let document = try? JSONDecoder().decode(ProgressDocument.self, from: data) else {
            return ProgressDocument()
        }
        return document
    }

    private func removeLegacyFileIfNeeded() {
        let url = Self.legacyProgressURL
        if FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.removeItem(at: url)
        }
    }

    private static var legacyProgressURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("progress.json")
    }

    private static func loadDesign() -> [Level] {
        guard let url = Bundle.main.url(forResource: "levels", withExtension: "json") else {
            assertionFailure("levels.json was not found in the bundle.")
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            let document = try JSONDecoder().decode(LevelsDocument.self, from: data)
            return document.levels.sorted { $0.id < $1.id }
        } catch {
            assertionFailure("Failed to read levels.json: \(error)")
            return []
        }
    }
}
