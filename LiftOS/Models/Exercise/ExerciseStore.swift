//
//  ExerciseStore.swift
//  LiftOS
//
//  Created by Garrett Curtis on 9/17/25.
//

// ExerciseStore.swift
// A small façade around SwiftData for reads/writes and first-run seeding.

import SwiftUI
import SwiftData

@MainActor
final class ExerciseStore: ObservableObject {

    private let modelContext: ModelContext
    @AppStorage("hasSeededExercises") private var hasSeededExercises: Bool = false

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Seeding
    func seedIfNeeded() throws {
        guard !hasSeededExercises else { return }

        // Load bundled JSON (150+ exercises) and insert as .prefill
        // See: exercises.json in the app bundle.
        if let url = Bundle.main.url(forResource: "exercises", withExtension: "json") {
            let data = try Data(contentsOf: url)
            let items = try JSONDecoder().decode([SeedExercise].self, from: data)

            // Idempotent-ish: only insert if same name+type doesn't already exist.
            for item in items {
                if try !exists(name: item.name, type: item.type) {
                    let ex = Exercise(
                        name: item.name,
                        source: .prefill,
                        muscleGroup: item.muscleGroup,
                        type: item.type,
                        loadBasis: item.loadBasis,   // pass through (defaults cover nil)
                        youtubeVideoID: item.youtubeVideoID
                    )
                    modelContext.insert(ex)
                }
            }
            try modelContext.save()
            hasSeededExercises = true
        } else {
            // If the file is missing, we just move on (customs will still work).
            // You can assert in debug if you prefer.
            #if DEBUG
            print("⚠️ exercises.json not found in bundle.")
            #endif
        }
    }

    // MARK: - Queries
    func fetchCustoms() throws -> [Exercise] {
        let descriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate { $0.sourceRaw == "custom" },
            sortBy: [SortDescriptor(\.name, order: .forward)]
        )
        return try modelContext.fetch(descriptor)
    }
    func fetchPrefills() throws -> [Exercise] {
        let descriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate { $0.sourceRaw == "prefill" },
            sortBy: [SortDescriptor(\.name, order: .forward)]
        )
        return try modelContext.fetch(descriptor)
    }
    // Convenience read-only properties for UI layers that don't want to try/catch
    var customs: [Exercise] { (try? fetchCustoms()) ?? [] }
    var prefills: [Exercise] { (try? fetchPrefills()) ?? [] }

    // MARK: - Mutations (Customs)
    func addCustom(name: String,
                   muscleGroup: Exercise.MuscleGroup,
                   type: Exercise.ExerciseType,
                   youtubeVideoID: String?) throws {
        // Basic dedupe: avoid duplicate custom name+type
        guard try !exists(name: name, type: type) else { throw ExerciseError.duplicateName }

        let ex = Exercise(name: name,
                          source: .custom,
                          muscleGroup: muscleGroup,
                          type: type,
                          youtubeVideoID: youtubeVideoID)
        modelContext.insert(ex)
        try modelContext.save()
    }

    func delete(_ exercise: Exercise) throws {
        modelContext.delete(exercise)
        try modelContext.save()
    }

    func update(_ exercise: Exercise,
                name: String,
                muscleGroup: Exercise.MuscleGroup,
                type: Exercise.ExerciseType,
                youtubeVideoID: String?) throws {
        // If name/type changed, enforce uniqueness
        if (exercise.name != name || exercise.type != type),
           try exists(name: name, type: type) {
            throw ExerciseError.duplicateName
        }
        exercise.name = name
        exercise.muscleGroup = muscleGroup
        exercise.type = type
        exercise.youtubeVideoID = youtubeVideoID
        try modelContext.save()
    }

    // MARK: - Helpers
    private func exists(name: String, type: Exercise.ExerciseType) throws -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        // Fetch by type only (supported in #Predicate), then filter in-memory for case-insensitive name match.
        let typeOnlyDescriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate { $0.typeRaw == type.rawValue }
        )
        let candidates = try modelContext.fetch(typeOnlyDescriptor)
        return candidates.contains { candidate in
            candidate.name.trimmingCharacters(in: .whitespacesAndNewlines)
                .localizedCaseInsensitiveCompare(trimmed) == .orderedSame
        }
    }

    // MARK: - Diagnostics
    // All prefills count
    func countPrefills() throws -> Int {
        let v = Exercise.Source.prefill.rawValue
        let d = FetchDescriptor<Exercise>(
            predicate: #Predicate { $0.sourceRaw == v }
        )
        return try modelContext.fetchCount(d)
    }

    // Prefills by muscle
    func countPrefills(by muscle: Exercise.MuscleGroup) throws -> Int {
        let v = Exercise.Source.prefill.rawValue
        let m = muscle.rawValue
        let d = FetchDescriptor<Exercise>(
            predicate: #Predicate { $0.sourceRaw == v && $0.muscleGroupRaw == m }
        )
        return try modelContext.fetchCount(d)
    }

    // Sample prefills
    func samplePrefills(limit: Int = 10) throws -> [Exercise] {
        let v = Exercise.Source.prefill.rawValue
        var d = FetchDescriptor<Exercise>(
            predicate: #Predicate { $0.sourceRaw == v },
            sortBy: [SortDescriptor(\.name)]
        )
        d.fetchLimit = limit
        return try modelContext.fetch(d)
    }

    // MARK: - Notes
    func addNote(for exercise: Exercise, text: String) throws {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let note = ExerciseNote(text: trimmed, exercise: exercise)
        modelContext.insert(note)
        try modelContext.save()
    }

    // Fetch the newest note for display
    func latestNote(for exercise: Exercise) throws -> ExerciseNote? {
        // We can read from exercise.notes (already loaded) or query; keeping it simple:
        return exercise.notes.sorted { $0.createdAt > $1.createdAt }.first
    }

    enum ExerciseError: LocalizedError {
        case duplicateName
        var errorDescription: String? {
            switch self {
            case .duplicateName:
                return "An exercise with this name and type already exists."
            }
        }
    }
}

// MARK: - Seed DTO
struct SeedExercise: Decodable {
    let name: String
    let muscleGroup: Exercise.MuscleGroup
    let type: Exercise.ExerciseType
    let youtubeVideoID: String?
    let loadBasis: Exercise.LoadBasis? // <- NEW (optional so older JSON still works)
}
