//
//  SessionSummary.swift
//  LiftOS
//
//  Created by Garrett Curtis on 9/13/25.
//
import Foundation

struct CompletedSet: Identifiable, Codable, Hashable {
    let id: UUID
    let exerciseName: String
    let index: Int
    let weight: Double?
    let reps: Int?
    let rir: Int?
    
    init(from set: ExerciseSet, exerciseName: String) {
        self.id = set.id
        self.exerciseName = exerciseName
        self.index = set.index
        self.weight = set.weight
        self.reps = set.reps
        self.rir = set.rir
    }

    var volume: Double {
        guard let w = weight, let r = reps else { return 0 }
        return w * Double(r)
    }
}

struct SessionSummary: Identifiable, Codable {
    var id = UUID()
    let title: String
    let date: Date
    let sets: [CompletedSet]
    var durationSeconds: Int? = nil

    var totalSets: Int { sets.count }
    var totalVolume: Double { sets.reduce(0) { $0 + $1.volume } }
}

/// Super-simple JSON store (file-backed). Good enough for MVP.
final class SummaryStore {
    static let shared = SummaryStore()
    private let fileURL: URL = {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("session_summaries.json")
    }()

    private(set) var summaries: [SessionSummary] = []

    func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        if let decoded = try? JSONDecoder().decode([SessionSummary].self, from: data) {
            summaries = decoded
        }
    }

    func save(_ summary: SessionSummary) {
        summaries.append(summary)
        if let data = try? JSONEncoder().encode(summaries) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }
}
