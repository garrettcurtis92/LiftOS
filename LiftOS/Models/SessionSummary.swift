import Foundation

struct CompletedSet: Identifiable, Codable, Hashable { let id: UUID; let exerciseName: String; let index: Int; let weight: Double?; let reps: Int?; let rir: Int?; init(from set: ExerciseSet, exerciseName: String) { self.id = set.id; self.exerciseName = exerciseName; self.index = set.index; self.weight = set.weight; self.reps = set.reps; self.rir = set.rir } ; var volume: Double { guard let w = weight, let r = reps else { return 0 }; return w * Double(r) } }

struct SessionSummary: Identifiable, Codable { var id = UUID(); let title: String; let date: Date; let sets: [CompletedSet]; var durationSeconds: Int? = nil; var userInfo: [String: Any]? = nil
    private enum CodingKeys: String, CodingKey { case id, title, date, sets, durationSeconds, userInfo }
    init(from decoder: Decoder) throws { let c = try decoder.container(keyedBy: CodingKeys.self); id = try c.decode(UUID.self, forKey: .id); title = try c.decode(String.self, forKey: .title); date = try c.decode(Date.self, forKey: .date); sets = try c.decode([CompletedSet].self, forKey: .sets); durationSeconds = try c.decodeIfPresent(Int.self, forKey: .durationSeconds); if let data = try c.decodeIfPresent(Data.self, forKey: .userInfo) { userInfo = try JSONSerialization.jsonObject(with: data) as? [String: Any] } }
    func encode(to encoder: Encoder) throws { var c = encoder.container(keyedBy: CodingKeys.self); try c.encode(id, forKey: .id); try c.encode(title, forKey: .title); try c.encode(date, forKey: .date); try c.encode(sets, forKey: .sets); try c.encodeIfPresent(durationSeconds, forKey: .durationSeconds); if let userInfo = userInfo { let data = try JSONSerialization.data(withJSONObject: userInfo); try c.encode(data, forKey: .userInfo) } }
    init(title: String, date: Date, sets: [CompletedSet]) { self.title = title; self.date = date; self.sets = sets }
}

final class SummaryStore { static let shared = SummaryStore(); private let fileURL: URL = { let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!; return dir.appendingPathComponent("session_summaries.json") }(); private(set) var summaries: [SessionSummary] = [] ; func load() { guard let data = try? Data(contentsOf: fileURL) else { return }; if let decoded = try? JSONDecoder().decode([SessionSummary].self, from: data) { summaries = decoded } } ; func save(_ summary: SessionSummary) { summaries.append(summary); if let data = try? JSONEncoder().encode(summaries) { try? data.write(to: fileURL, options: .atomic) } }
}
