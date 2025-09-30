//
//  ProgressionRulesGenerator.swift
//  LiftOS
//
//  Generates a tailored ProgressionRules.json from the bundled exercises.json
//  using heuristics requested by the user.
//

import Foundation

struct SeedExerciseForRules: Decodable {
    let name: String
    let muscleGroup: String
    let type: String
    let youtubeVideoID: String?
    let loadBasis: String?
}

@MainActor
enum ProgressionRulesGenerator {

    static func generateFromExercisesJSON() async {
        // Load exercises.json from bundle
        guard let url = Bundle.main.url(forResource: "exercises", withExtension: "json") else { return }
        guard let data = try? Data(contentsOf: url) else { return }
        guard let items = try? JSONDecoder().decode([SeedExerciseForRules].self, from: data) else { return }

        // Build rules map
        var rules: [String: ProgressionRule] = [:]
        for item in items {
            let lower = item.name.lowercased()
            // Assisted movements (machine assistance): decrease assistance by 5 lb
            if item.type.lowercased() == "machineassistance" {
                rules[item.name] = ProgressionRule(rawProgression: "weight", weightIncrement: 5.0, repIncrement: nil, rawProgressDirection: .decrease)
                continue
            }
            // Barbell type: +5 lb
            if item.type.lowercased() == "barbell" {
                rules[item.name] = ProgressionRule(rawProgression: "weight", weightIncrement: 5.0, repIncrement: nil, rawProgressDirection: .increase)
                continue
            }
            // Bodyweight loadable (weighted variants by type): +2.5 lb
            if item.type.lowercased() == "bodyweightloadable" {
                rules[item.name] = ProgressionRule(rawProgression: "weight", weightIncrement: 2.5, repIncrement: nil, rawProgressDirection: .increase)
                continue
            }
            // Dumbbell press/row by type: +2.5 lb
            if item.type.lowercased() == "dumbbell" && (lower.contains("press") || lower.contains("row")) {
                rules[item.name] = ProgressionRule(rawProgression: "weight", weightIncrement: 2.5, repIncrement: nil, rawProgressDirection: .increase)
                continue
            }
            // Everything else: +1 rep
            rules[item.name] = ProgressionRule(rawProgression: "reps", weightIncrement: nil, repIncrement: 1, rawProgressDirection: .increase)
        }

        // Write to Documents/ProgressionRules.json
        let file = ProgressionRulesFile(exercises: rules)
        guard let out = try? JSONEncoder().encode(file) else { return }
        if let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let url = docs.appendingPathComponent("ProgressionRules.json")
            try? out.write(to: url, options: .atomic)
        }
    }
}
