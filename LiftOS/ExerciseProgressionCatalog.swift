import Foundation

enum ProgressionMode: String, Codable {
    case weight
    case reps
}

enum ProgressDirection: String, Codable {
    case increase
    case decrease
}

struct ExerciseProgressionRule: Decodable {
    let name: String
    let muscleGroup: String
    let equipType: EquipType
    let progression: ProgressionMode?
    let weightIncrement: Double?
    let repIncrement: Int?
    let loadBasis: String?
    let progressDirection: ProgressDirection?
    // Assistance semantics (optional)
    let minAssistance: Double?
    let maxAssistance: Double?
    let assistanceStep: Double?

    enum CodingKeys: String, CodingKey {
        case name
        case muscleGroup
        case type
        case progression
        case weightIncrement
        case repIncrement
        case loadBasis
        case progressDirection
        case minAssistance
        case maxAssistance
        case assistanceStep
    }

    init(name: String,
         muscleGroup: String,
         equipType: EquipType,
         progression: ProgressionMode?,
         weightIncrement: Double?,
         repIncrement: Int?,
         loadBasis: String?,
         progressDirection: ProgressDirection?,
         minAssistance: Double?,
         maxAssistance: Double?,
         assistanceStep: Double?) {
        self.name = name
        self.muscleGroup = muscleGroup
        self.equipType = equipType
        self.progression = progression
        self.weightIncrement = weightIncrement
        self.repIncrement = repIncrement
        self.loadBasis = loadBasis
        self.progressDirection = progressDirection
        self.minAssistance = minAssistance
        self.maxAssistance = maxAssistance
        self.assistanceStep = assistanceStep
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let name = try c.decode(String.self, forKey: .name)
        let muscleGroup = try c.decode(String.self, forKey: .muscleGroup)
        let rawType = try? c.decode(String.self, forKey: .type)
        let progression = try? c.decode(ProgressionMode.self, forKey: .progression)
        let weightIncrement = try? c.decode(Double.self, forKey: .weightIncrement)
        let repIncrement = try? c.decode(Int.self, forKey: .repIncrement)
        let loadBasis = try? c.decode(String.self, forKey: .loadBasis)
        let progressDirection = try? c.decode(ProgressDirection.self, forKey: .progressDirection)
        let minAssistance = try? c.decode(Double.self, forKey: .minAssistance)
        let maxAssistance = try? c.decode(Double.self, forKey: .maxAssistance)
        let assistanceStep = try? c.decode(Double.self, forKey: .assistanceStep)

        // Map raw type -> EquipType using lowercase
        let mappedEquip: EquipType = {
            guard let t = rawType?.lowercased() else { return .unknown }
            switch t {
            case "barbell": return .barbell
            case "dumbbell": return .dumbbell
            case "machine": return .machine
            case "cable": return .cable
            case "bodyweightonly": return .bodyweightOnly
            case "smithmachine": return .smithMachine
            case "machineassistance": return .machineAssistance
            case "bodyweightloadable": return .bodyweightLoadable
            default:
                #if DEBUG
                print("[Catalog] Unknown equip type '\(t)' for exercise '\(name)'. Will treat as .unknown; validator may warn.")
                #endif
                return .unknown
            }
        }()

        self.init(
            name: name,
            muscleGroup: muscleGroup,
            equipType: mappedEquip,
            progression: progression,
            weightIncrement: weightIncrement,
            repIncrement: repIncrement,
            loadBasis: loadBasis,
            progressDirection: progressDirection,
            minAssistance: minAssistance,
            maxAssistance: maxAssistance,
            assistanceStep: assistanceStep
        )
    }
}

/// Note: weightIncrement values are assumed to be in the app's base unit (lbs) and are used as-is.
final class ExerciseProgressionCatalog {
    static let shared = ExerciseProgressionCatalog()

    private var rules: [String: ExerciseProgressionRule] = [:]

    private init() {
        loadRules()
    }

    private func loadRules() {
        guard let url = Bundle.main.url(forResource: "exercises", withExtension: "json") else {
            return
        }
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([ExerciseProgressionRule].self, from: data)
            var dictionary: [String: ExerciseProgressionRule] = [:]
            for rule in decoded {
                dictionary[ExerciseKey.normalize(rule.name)] = rule
            }
            self.rules = dictionary
        } catch {
            // On failure, keep rules empty
            self.rules = [:]
        }
    }

    func rule(for exerciseName: String) -> ExerciseProgressionRule? {
        return rules[ExerciseKey.normalize(exerciseName)]
    }

    /// Returns all loaded rules for validation.
    func allRules() -> [ExerciseProgressionRule] { Array(rules.values) }
}
