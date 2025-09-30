import Foundation

// Stores last-entered reps per exercise (by set index) scoped to a mesocycle
struct StoredReps: Codable { var perSet: [Int: Int] }

final class RepHistoryStore {
    static let shared = RepHistoryStore()
    private let key = "progression.reps.v1"
    private var cache: [String: StoredReps] = [:]

    private init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([String: StoredReps].self, from: data) {
            cache = decoded
        }
    }

    private func makeKey(mesocycleID: UUID, exerciseName: String) -> String {
        return "\(mesocycleID.uuidString)::\(exerciseName.lowercased())"
    }

    func get(mesocycleID: UUID, exerciseName: String) -> [Int: Int]? {
        cache[makeKey(mesocycleID: mesocycleID, exerciseName: exerciseName)]?.perSet
    }

    func set(mesocycleID: UUID, exerciseName: String, repsBySet: [Int: Int]) {
        cache[makeKey(mesocycleID: mesocycleID, exerciseName: exerciseName)] = StoredReps(perSet: repsBySet)
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(cache) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
