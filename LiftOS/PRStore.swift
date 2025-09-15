//
//  PRStore.swift
//  LiftOS
//
//  Created by Garrett Curtis on 9/15/25.
//
import Foundation

struct ExercisePR: Codable, Equatable {
    var bestTopSetLoad: Double?   // heaviest weight (ignores reps)
    var bestVolume: Double?       // sum(weight*reps) in a single session
}

final class PRStore {
    static let shared = PRStore()
    private let key = "liftos.prs.v1"
    private var map: [String: ExercisePR] = [:]   // exerciseName -> PRs

    private init() { load() }

    func load() {
        guard let data = UserDefaults.standard.data(forKey: key) else { return }
        if let decoded = try? JSONDecoder().decode([String: ExercisePR].self, from: data) {
            map = decoded
        }
    }

    func save() {
        if let data = try? JSONEncoder().encode(map) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func pr(for exerciseName: String) -> ExercisePR? {
        map[exerciseName]
    }

    func updatePR(exerciseName: String, topSetLoad: Double?, volume: Double?) -> (newTopPR: Bool, newVolumePR: Bool) {
        var entry = map[exerciseName] ?? ExercisePR(bestTopSetLoad: nil, bestVolume: nil)
        var topChanged = false
        var volChanged = false

        if let t = topSetLoad, t > (entry.bestTopSetLoad ?? 0) {
            entry.bestTopSetLoad = t
            topChanged = true
        }
        if let v = volume, v > (entry.bestVolume ?? 0) {
            entry.bestVolume = v
            volChanged = true
        }
        map[exerciseName] = entry
        return (topChanged, volChanged)
    }
}
