//
//  ProgressionCatalog.swift
//  LiftOS
//
//  Defines a JSON-backed progression catalog with per-exercise rules.
//

import Foundation

enum EquipType: String, Codable {
    case barbell, dumbbell, machine, cable, bodyweightOnly, smithMachine, machineAssistance, bodyweightLoadable, unknown
}

extension EquipType {
    var machineFineSteps: Bool { self == .machine || self == .cable || self == .smithMachine || self == .machineAssistance }
}

// Concrete rule type loaded from JSON
struct ProgressionRule: Codable {
    var rawProgression: String // JSON key: "progression" (e.g., "weight" | "reps")
    var weightIncrement: Double? = nil // e.g., 5.0 or 2.5
    var repIncrement: Int? = nil // e.g., 1
    var rawProgressDirection: ProgressDirection? = nil // JSON key: "progressDirection"; default .increase
    var rawEquipType: String? = nil // JSON key: "type" from exercises.json if present
    var minAssistance: Double? = nil // optional for assisted machines (defaults to 0)
    var assistanceStep: Double? = nil // optional override for assistance decrement (defaults to weightIncrement)

    enum CodingKeys: String, CodingKey {
        case rawProgression = "progression"
        case weightIncrement
        case repIncrement
        case rawProgressDirection = "progressDirection"
        case rawEquipType = "type"
        case minAssistance
        case assistanceStep
    }
}

// JSON layout: { "exercises": { "Exercise Name": { ...rule... }, ... } }
struct ProgressionRulesFile: Codable {
    var exercises: [String: ProgressionRule]
}

private func normalizeExerciseName(_ name: String) -> String {
    return name.lowercased()
}

// Bridge to engine protocol expected by MesocycleProgressionEngine
protocol EngineProgressionRule {
    var progression: EngineProgressionMode { get }
    var weightIncrement: Double? { get }
    var repIncrement: Int? { get }
    var progressDirection: ProgressDirection { get }
}

extension ProgressionRule: EngineProgressionRule {
    var progression: EngineProgressionMode {
        switch self.rawProgression.lowercased() {
        case "weight": return .weight
        case "reps": return .reps
        default: return .unknown
        }
    }
    var progressDirection: ProgressDirection { self.rawProgressDirection ?? .increase }
    
    var equipType: EquipType {
        guard let raw = rawEquipType?.lowercased() else { return .unknown }
        switch raw {
        case "barbell": return .barbell
        case "dumbbell": return .dumbbell
        case "machine": return .machine
        case "cable": return .cable
        case "bodyweightonly": return .bodyweightOnly
        case "smithmachine": return .smithMachine
        case "machineassistance": return .machineAssistance
        case "bodyweightloadable": return .bodyweightLoadable
        default: return .unknown
        }
    }
}

// The catalog loader. Looks for ProgressionRules.json in the main bundle.
final class EngineProgressionCatalog {
    static let shared = EngineProgressionCatalog()

    private var rules: [String: ProgressionRule] = [:] // key: normalized exercise name
    private var loaded = false

    private init() {}

    private func loadIfNeeded() {
        guard !loaded else { return }
        defer { loaded = true }

        func load(from url: URL) -> [String: ProgressionRule]? {
            do {
                let data = try Data(contentsOf: url)
                let decoded = try JSONDecoder().decode(ProgressionRulesFile.self, from: data)
                var map: [String: ProgressionRule] = [:]
                for (name, rule) in decoded.exercises { map[normalizeExerciseName(name)] = rule }
                return map
            } catch { return nil }
        }

        // 1) Try Documents/ProgressionRules.json (generated file)
        if let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let generatedURL = docs.appendingPathComponent("ProgressionRules.json")
            if FileManager.default.fileExists(atPath: generatedURL.path), let m = load(from: generatedURL) {
                self.rules = m
                return
            }
        }

        // 2) Fall back to bundled ProgressionRules.json
        if let url = Bundle.main.url(forResource: "ProgressionRules", withExtension: "json"), let m = load(from: url) {
            self.rules = m
            return
        }

        // 3) Nothing found; keep empty and rely on heuristics
        self.rules = [:]
    }

    func rule(for exerciseName: String) -> EngineProgressionRule? {
        loadIfNeeded()
        let key = normalizeExerciseName(exerciseName)
        if let r = rules[key] { return r }
        // Derive rule based on name heuristics
        let lower = exerciseName.lowercased()

        // 1) Assisted movements: progress by decreasing weight (assistance) by 5 lb
        if lower.contains("assisted") {
            return ProgressionRule(
                rawProgression: "weight",
                weightIncrement: 5.0,
                repIncrement: nil,
                rawProgressDirection: .decrease
            )
        }

        // 2) Barbell types: +5 lb
        if lower.contains("barbell") ||
           lower.contains("bench press") || lower.contains("back squat") || lower.contains("front squat") ||
           lower.contains("deadlift") || lower.contains("overhead press") || lower.contains("ohp") ||
           lower.contains("barbell row") || lower.contains("pendlay") || lower.contains("hip thrust") {
            return ProgressionRule(
                rawProgression: "weight",
                weightIncrement: 5.0,
                repIncrement: nil,
                rawProgressDirection: .increase
            )
        }

        // 3) Bodyweight loadable (weighted variants): +2.5 lb
        if lower.contains("weighted ") || lower.contains("weight belt") || lower.contains("plate dip") || lower.contains("plate pull-up") {
            return ProgressionRule(
                rawProgression: "weight",
                weightIncrement: 2.5,
                repIncrement: nil,
                rawProgressDirection: .increase
            )
        }

        // 4) Dumbbell press/row: +2.5 lb
        if (lower.contains("dumbbell") || lower.contains("db")) && (lower.contains("press") || lower.contains("row")) {
            return ProgressionRule(
                rawProgression: "weight",
                weightIncrement: 2.5,
                repIncrement: nil,
                rawProgressDirection: .increase
            )
        }

        // 5) Everything else (cable or dumbbell movements that aren't a press or row): +1 rep per week, hold weight
        return ProgressionRule(
            rawProgression: "reps",
            weightIncrement: nil,
            repIncrement: 1,
            rawProgressDirection: .increase
        )
    }
}
