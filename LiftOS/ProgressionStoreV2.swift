import Foundation

enum LastProgressAction: String, Codable {
    case progressed
    case held
    case regressed
}

struct StoredNextTargetV2: Codable {
    var nextWeight: Double?
    var nextRepTargetLower: Int?
    var nextRepTargetUpper: Int?
    var missStreak: Int = 0
    var lastAction: LastProgressAction?
    var lastUpdatedAt: Date?
}

actor ProgressionStoreV2 {
    static let shared = ProgressionStoreV2()

    private let userDefaultsKey = "progression.nextTargets.v2"
    private var cache: [String: StoredNextTargetV2] = [:]
    private var hydrationTask: Task<[String: StoredNextTargetV2], Never>?

    private init() {
        hydrationTask = Task.detached(priority: .utility) { [userDefaultsKey] in
            // Decode off-main
            guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
                return [:]
            }
            do {
                // JSONDecoder work off-main inside this detached task
                let decoded = try JSONDecoder().decode([String: StoredNextTargetV2].self, from: data)
                return decoded
            } catch {
                return [:]
            }
        }
    }

    private func makeKey(mesocycleID: UUID, exercise: String) -> String {
        let norm = ExerciseKey.normalize(exercise)
        return "\(mesocycleID.uuidString)::\(norm)"
    }

    private func ensureHydrated() async {
        if let task = hydrationTask {
            let decoded = await task.value
            cache = decoded
            hydrationTask = nil
        }
    }

    private func persist() {
        let snapshot = cache
        Task.detached(priority: .utility) {
            do {
                let encoded = try JSONEncoder().encode(snapshot)
                UserDefaults.standard.set(encoded, forKey: self.userDefaultsKey)
            } catch {
                // Ignore encoding errors for now; consider logging in the future
            }
        }
    }

    // MARK: - Public Async API

    func getTarget(mesocycleID: UUID, exercise: String) async -> StoredNextTargetV2? {
        await ensureHydrated()
        let key = makeKey(mesocycleID: mesocycleID, exercise: exercise)
        return cache[key]
    }

    func updateTarget(mesocycleID: UUID, exercise: String, mutate: (inout StoredNextTargetV2) -> Void) async {
        await ensureHydrated()
        let key = makeKey(mesocycleID: mesocycleID, exercise: exercise)
        var current = cache[key] ?? StoredNextTargetV2()
        mutate(&current)
        cache[key] = current
        persist()
    }

    func migrateFromV1IfNeeded() async {
        await ensureHydrated()
        let migratedKey = "progression.migratedToV2"
        let already = UserDefaults.standard.bool(forKey: migratedKey)
        guard !already else { return }

        // Pull all v1 entries and convert
        let all = ProgressionStore.shared.allEntries()
        for entry in all {
            let v2 = StoredNextTargetV2(
                nextWeight: entry.value.nextWeight,
                nextRepTargetLower: entry.value.nextRepTargetLower,
                nextRepTargetUpper: entry.value.nextRepTargetUpper,
                missStreak: 0,
                lastAction: nil,
                lastUpdatedAt: nil
            )
            let key = makeKey(mesocycleID: entry.mesocycleID, exercise: entry.exerciseName)
            cache[key] = v2
        }
        persist()
        UserDefaults.standard.set(true, forKey: migratedKey)
    }
}

