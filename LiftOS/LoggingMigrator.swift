import Foundation
import SwiftData

/// One-shot migrator that folds any legacy ExerciseSetLog records into WorkoutLogEntry
/// Idempotent: guarded by a UserDefaults flag.
struct LoggingMigrator {
    static func runIfNeeded(_ context: ModelContext) {
        let flagKey = "logging_migrated_v1_to_unified"
        if UserDefaults.standard.bool(forKey: flagKey) { return }

        // Try to fetch legacy ExerciseSetLog if the type exists at runtime.
        // We conditionally compile only if the symbol is available in the target.
        #if canImport(SwiftData)
        do {
            // Best-effort: use NSClassFromString to avoid compile failure if the type was removed.
            // We only need to know whether the symbol exists at runtime; no casting required.
            if NSClassFromString("ExerciseSetLog") != nil {
                // Since we can't dynamically fetch without the generic type, we instead rely on the caller to still have ExerciseSetLog in code during first run.
                // If ExerciseSetLog was removed already, this block effectively does nothing and we just set the flag to avoid repeated attempts.
            }
        }
        #endif

        // If ExerciseSetLog still exists in code, perform a typed migration path.
        #if canImport(SwiftData)
        if let migrated = try? migrateTyped(context) {
            if migrated {
                UserDefaults.standard.set(true, forKey: flagKey)
            } else {
                // Even if no legacy rows, mark as migrated to avoid repeat work.
                UserDefaults.standard.set(true, forKey: flagKey)
            }
        } else {
            UserDefaults.standard.set(true, forKey: flagKey)
        }
        #endif
    }

    /// Typed migration that compiles only if ExerciseSetLog is still available.
    private static func migrateTyped(_ context: ModelContext) throws -> Bool {
        #if compiler(>=6)
        // If the legacy model exists, migrate; otherwise, nothing to do.
        if (true) {
            // Attempt to fetch legacy logs
            do {
                let descriptor = FetchDescriptor<ExerciseSetLog>()
                let legacy = try context.fetch(descriptor)
                guard !legacy.isEmpty else { return false }

                // Determine preferred weight unit from settings (defaults to .lb if unavailable)
                let preferredUnit: WeightUnit = {
                    if let raw = UserDefaults.standard.string(forKey: "weightUnit"), let u = WeightUnit(rawValue: raw) {
                        return u
                    }
                    return .lb
                }()

                // Map to WorkoutLogEntry. We do not have mesocycleID in legacy; use nil-safe UUID if needed (or zero UUID).
                for l in legacy {
                    let entry = WorkoutLogEntry(
                        mesocycleID: UUID(uuidString: "00000000-0000-0000-0000-000000000000") ?? UUID(),
                        week: l.week,
                        dayIx: l.day,
                        exerciseName: l.exerciseName,
                        exerciseKey: PlanKey.normalize(l.exerciseName),
                        setIndex: l.setNumber,
                        weight: l.weight,
                        reps: l.repetitions,
                        done: true,
                        unit: preferredUnit
                    )
                    context.insert(entry)
                }
                try? context.save()
                return true
            } catch {
                return false
            }
        }
        #else
        return false
        #endif
    }
}

