//
//  ProgressionStore.swift
//  LiftOS
//
//  Created by Garrett Curtis on 9/23/25.
//
import Foundation

struct StoredNextTarget: Codable {
    var nextWeight: Double?
    var nextRepTargetLower: Int?
    var nextRepTargetUpper: Int?
}

final class ProgressionStore {
    static let shared = ProgressionStore()
    private let key = "progression.nextTargets.v1"

    private var cache: [String: StoredNextTarget] = [:]

    private init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([String: StoredNextTarget].self, from: data) {
            cache = decoded
        }
    }

    private func makeKey(mesocycleID: UUID, exerciseName: String) -> String {
        "\(mesocycleID.uuidString)::\(exerciseName.lowercased())"
    }

    func set(mesocycleID: UUID, exerciseName: String, next: StoredNextTarget) {
        cache[makeKey(mesocycleID: mesocycleID, exerciseName: exerciseName)] = next
        persist()
    }

    func get(mesocycleID: UUID, exerciseName: String) -> StoredNextTarget? {
        cache[makeKey(mesocycleID: mesocycleID, exerciseName: exerciseName)]
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(cache) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    /// Returns all stored v1 targets along with parsed mesocycleID and exerciseName.
    /// Key format is "<uuid>::<exercise-name-lowercased>".
    func allEntries() -> [(mesocycleID: UUID, exerciseName: String, value: StoredNextTarget)] {
        var result: [(UUID, String, StoredNextTarget)] = []
        for (key, val) in cache {
            let parts = key.split(separator: "::", maxSplits: 1, omittingEmptySubsequences: false)
            guard parts.count == 2, let uuid = UUID(uuidString: String(parts[0])) else { continue }
            let name = String(parts[1])
            result.append((uuid, name, val))
        }
        return result
    }
}
