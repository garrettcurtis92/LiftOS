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
    var userInfo: [String: Any]? = nil

    var totalSets: Int { sets.count }
    var totalVolume: Double { sets.reduce(0) { $0 + $1.volume } }
    
    // Custom coding keys to handle userInfo properly
    private enum CodingKeys: String, CodingKey {
        case id, title, date, sets, durationSeconds, userInfo
    }
    
    // Manual Codable implementation to handle [String: Any]
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        date = try container.decode(Date.self, forKey: .date)
        sets = try container.decode([CompletedSet].self, forKey: .sets)
        durationSeconds = try container.decodeIfPresent(Int.self, forKey: .durationSeconds)
        
        // Try to decode userInfo as JSON data
        if let data = try container.decodeIfPresent(Data.self, forKey: .userInfo) {
            userInfo = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        } else {
            userInfo = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(date, forKey: .date)
        try container.encode(sets, forKey: .sets)
        try container.encodeIfPresent(durationSeconds, forKey: .durationSeconds)
        
        // Encode userInfo as JSON data
        if let userInfo = userInfo {
            let data = try JSONSerialization.data(withJSONObject: userInfo)
            try container.encode(data, forKey: .userInfo)
        }
    }
    
    // Convenience initializer
    init(title: String, date: Date, sets: [CompletedSet]) {
        self.id = UUID()
        self.title = title
        self.date = date
        self.sets = sets
        self.durationSeconds = nil
        self.userInfo = nil
    }
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
