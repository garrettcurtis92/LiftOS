import Foundation

// MARK: - Buckets for picker UX (group -> muscle sets)
enum MuscleBucket: String, CaseIterable, Codable, Identifiable {
    case upperPush = "Upper Push"
    case upperPull = "Upper Pull"
    case legs      = "Legs"
    case accessory = "Accessory"

    var id: String { rawValue }

    var groups: [String] {
        switch self {
        case .upperPush: return ["Chest", "Triceps", "Shoulders"]
        case .upperPull: return ["Back", "Biceps"]
        case .legs:      return ["Quads", "Glutes", "Hamstrings"]
        case .accessory: return ["Calves", "Traps", "Forearms"]
        }
    }
}

// MARK: - Day label style
enum DayLabelStyle: String, CaseIterable, Codable {
    case weekdays   // Mon, Tue...
    case generic    // Day 1, Day 2...
}

// MARK: - A reference to an exercise from the library
struct ExerciseRef: Codable, Hashable, Identifiable {
    var id: UUID
    var name: String
    var muscleGroup: String        // e.g. "Chest", "Back"
    var incrementStep: Double?     // optional (e.g., 2.5 kg)
    var repRange: ClosedRange<Int>? // optional, encode manually

    init(id: UUID = UUID(),
         name: String,
         muscleGroup: String,
         incrementStep: Double? = nil,
         repRange: ClosedRange<Int>? = nil) {
        self.id = id
        self.name = name
        self.muscleGroup = muscleGroup
        self.incrementStep = incrementStep
        self.repRange = repRange
    }

    // Codable for ClosedRange<Int>
    private enum CodingKeys: String, CodingKey { case id, name, muscleGroup, incrementStep, repLower, repUpper }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        muscleGroup = try c.decode(String.self, forKey: .muscleGroup)
        incrementStep = try c.decodeIfPresent(Double.self, forKey: .incrementStep)
        if let lo = try c.decodeIfPresent(Int.self, forKey: .repLower),
           let hi = try c.decodeIfPresent(Int.self, forKey: .repUpper) {
            repRange = lo...hi
        } else {
            repRange = nil
        }
    }
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(muscleGroup, forKey: .muscleGroup)
        try c.encodeIfPresent(incrementStep, forKey: .incrementStep)
        try c.encodeIfPresent(repRange?.lowerBound, forKey: .repLower)
        try c.encodeIfPresent(repRange?.upperBound, forKey: .repUpper)
    }
}

// MARK: - Draft day (builder-only)
struct DayDraft: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var name: String
    var exerciseRefs: [ExerciseRef] = []

    static func defaultDays(count: Int, style: DayLabelStyle) -> [DayDraft] {
        switch style {
        case .generic:
            return (1...count).map { DayDraft(name: "Day \($0)") }
        case .weekdays:
            let week = ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]
            return (0..<count).map { DayDraft(name: week[$0]) }
        }
    }
}

// MARK: - Draft mesocycle (builder-only)
struct MesoDraft: Codable {
    var weeks: Int                // 4–8 (default 6 = 5 + deload)
    var hasDeloadAtEnd: Bool      // true for MVP (last week)
    var daysPerWeek: Int          // 2–6
    var labelStyle: DayLabelStyle
    var days: [DayDraft]

    static func `default`() -> MesoDraft {
        let weeks = 6
        let style: DayLabelStyle = .generic
        let days = DayDraft.defaultDays(count: 2, style: style)
        return MesoDraft(weeks: weeks,
                         hasDeloadAtEnd: true,
                         daysPerWeek: 2,
                         labelStyle: style,
                         days: days)
    }
}

// MARK: - Active mesocycle store (simple UserDefaults for now)
final class ActiveMesocycleStore {
    static let shared = ActiveMesocycleStore()
    private let key = "liftos.activeMesoDraft.v1"
    private init() {}

    func load() -> MesoDraft? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(MesoDraft.self, from: data)
    }
    func save(_ draft: MesoDraft) {
        if let data = try? JSONEncoder().encode(draft) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    func clear() { UserDefaults.standard.removeObject(forKey: key) }
}