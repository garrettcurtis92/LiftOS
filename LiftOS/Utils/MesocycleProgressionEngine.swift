//
//  MesocycleProgressionEngine.swift
//  LiftOS
//
//  Created by Garrett Curtis on 9/23/25.
//
import Foundation
import SwiftUI
import SwiftData

extension WeightUnit {
    var coarseStep: Double { self == .kg ? 2.5 : 5.0 }
    var fineStep: Double   { self == .kg ? 1.0 : 2.5 }
}

enum LoadRounding {
    static func rounded(_ raw: Double, unit: WeightUnit, equip: EquipType) -> Double {
        let step = equip.machineFineSteps ? unit.fineStep : unit.coarseStep
        return (raw / step).rounded() * step
    }
}

enum EngineProgressionMode {
    case weight
    case reps
    case unknown
}

struct ExerciseProgressInput: Hashable {
    let mesocycleID: UUID
    let exerciseName: String
    let isCompound: Bool
    let lastTopSetWeight: Double?   // e.g., heaviest set weight
    let lastTopSetReps: Int?        // reps on that top set
    let targetReps: ClosedRange<Int> // your current rep target window, e.g. 8...10
    let targetRIR: Int              // current week’s RIR target
    let achievedRIR: Int?           // actual logged RIR if you add it later (optional)
}

enum ProgressionAction: String, Codable {
    case progress, hold, regress
}

struct ExerciseProgressOutput: Codable {
    let action: ProgressionAction
    let nextWeight: Double?    // when compound logic progresses/holds/regresses
    let nextRepTarget: ClosedRange<Int>? // when isolation adds reps
    let nextAssistance: Double? // for assisted movements (weight on the assist stack)
}

enum ProgressionKind {
    case compound
    case isolation
}

// --- New types and extensions for progression catalog and stored state ---

/// New helper struct for decision context
struct DecisionContext {
    let rule: EngineProgressionRule?
    let lastStored: EngineStoredNextTargetV2?
    let progressDirection: ProgressDirection

    init(rule: EngineProgressionRule?, lastStored: EngineStoredNextTargetV2?) {
        self.rule = rule
        self.lastStored = lastStored
        self.progressDirection = rule?.progressDirection ?? .increase
    }
}

struct EngineStoredNextTargetV2 {
    let mesocycleID: UUID
    let exerciseName: String
    let progressKind: ProgressionKind
    let lastWeight: Double?
    let lastRepTarget: ClosedRange<Int>
    let missStreak: Int
    let lastAction: ProgressionAction
    let lastUpdatedAt: Date
}

// --- MesocycleProgressionEngine with new decideNext(...) method and helpers ---

enum MesocycleProgressionEngine {
    
    private struct SessionKey: Hashable { let week: Int; let day: Int }

    static func classifyKind(from name: String) -> ProgressionKind {
        let lower = name.lowercased()
        // Heuristics – tweak anytime or replace with a real field later
        let compoundKeys = [
            "squat","deadlift","bench","overhead","ohp","row","press","pull-up","pulldown","dip","hip thrust","rdl",
            "barbell","front squat","incline bench","pendlay","pullup","chin-up","chinup"
        ]
        if compoundKeys.contains(where: { lower.contains($0) }) {
            return .compound
        }
        return .isolation
    }

    // Baseline gating helpers (Wave G)
    @MainActor
    static func hasBaseline(mesocycleID: UUID, exerciseName: String, currentWeek: Int, currentDayIx: Int, modelContext: ModelContext) async -> Bool {
        let _meso = mesocycleID
        let _exercise = exerciseName
        let _week = currentWeek
        let _day = currentDayIx
        let _key = ExerciseKey.normalize(_exercise)
        let d = FetchDescriptor<WorkoutLogEntry>(
            predicate: #Predicate { entry in
                entry.mesocycleID == _meso &&
                entry.exerciseKey == _key &&
                (
                    entry.week < _week ||
                    (entry.week == _week && entry.dayIx < _day)
                ) &&
                entry.done == true &&
                entry.weight != nil && entry.reps != nil
            }
        )
        let fetched = (try? modelContext.fetch(d)) ?? []
        return !fetched.isEmpty
    }

    @MainActor
    static func priorTopSet(mesocycleID: UUID, exerciseName: String, currentWeek: Int, currentDayIx: Int, modelContext: ModelContext) async -> (weight: Double, reps: Int)? {
        let _meso = mesocycleID
        let _exercise = exerciseName
        let _week = currentWeek
        let _day = currentDayIx
        let _key = ExerciseKey.normalize(_exercise)
        let d = FetchDescriptor<WorkoutLogEntry>(
            predicate: #Predicate { entry in
                entry.mesocycleID == _meso &&
                entry.exerciseKey == _key &&
                (
                    entry.week < _week ||
                    (entry.week == _week && entry.dayIx < _day)
                ) &&
                entry.done == true &&
                entry.weight != nil && entry.reps != nil
            }
        )
        let fetched = (try? modelContext.fetch(d)) ?? []
        guard !fetched.isEmpty else { return nil }
        // Group by (week, dayIx)
        let grouped = Dictionary(grouping: fetched, by: { SessionKey(week: $0.week, day: $0.dayIx) })
        // Find the most recent earlier session by max (week, dayIx)
        if let latestKey = grouped.keys.max(by: { (a, b) in
            if a.week == b.week { return a.day < b.day }
            return a.week < b.week
        }), let entries = grouped[latestKey] {
            // Choose heaviest set from that session
            let top = entries.compactMap { e -> (Double, Int)? in
                if let w = e.weight, let r = e.reps { return (w, r) }
                return nil
            }.max(by: { $0.0 < $1.0 })
            return top
        }
        return nil
    }

    @MainActor
    static func priorSessionCount(mesocycleID: UUID, exerciseName: String, currentWeek: Int, currentDayIx: Int, modelContext: ModelContext) async -> Int {
        let _meso = mesocycleID
        let _exercise = exerciseName
        let _week = currentWeek
        let _day = currentDayIx
        let _key = ExerciseKey.normalize(_exercise)
        let d = FetchDescriptor<WorkoutLogEntry>(
            predicate: #Predicate { entry in
                entry.mesocycleID == _meso &&
                entry.exerciseKey == _key &&
                (
                    entry.week < _week ||
                    (entry.week == _week && entry.dayIx < _day)
                ) &&
                entry.done == true &&
                entry.weight != nil && entry.reps != nil
            }
        )
        let fetched = (try? modelContext.fetch(d)) ?? []
        let grouped = Dictionary(grouping: fetched, by: { SessionKey(week: $0.week, day: $0.dayIx) })
        return grouped.keys.count
    }

    static func nextTargets(
        input: ExerciseProgressInput,
        baseIncrements: (compound: Double, fallback: Double, isolationRepStep: Int) = (5.0, 2.5, 1),
        weightUnit: WeightUnit = .lb,
        completedSets: [ExerciseSet]? = nil
    ) -> ExerciseProgressOutput {

        let normalizedName = ExerciseKey.normalize(input.exerciseName)

        // Determine reps to evaluate based on heaviest completed set carry-over
        let repsForEval: Int? = {
            if let sets = completedSets {
                let top = sets.compactMap { s -> (Double, Int)? in
                    guard let w = s.weight, let r = s.reps else { return nil }
                    return (w, r)
                }.max(by: { $0.0 < $1.0 })
                return top?.1
            }
            return input.lastTopSetReps
        }()

        let inWindow: Bool = {
            guard let reps = repsForEval else { return false }
            return input.targetReps.contains(reps)
        }()

        // If we ever track achievedRIR, we can add: achievedRIR <= targetRIR as an additional pass condition
        let metTargets = inWindow // && (input.achievedRIR ?? input.targetRIR) <= input.targetRIR

        let equipType = ExerciseProgressionCatalog.shared.rule(for: normalizedName)?.equipType ?? .unknown

        switch input.isCompound ? ProgressionKind.compound : .isolation {

        case .compound:
            // Weight-centric progression
            let inc = baseIncrements.compound
            _  = baseIncrements.fallback

            guard let lastW = input.lastTopSetWeight else {
                // No prior load – start by holding (or set a baseline if you prefer)
                return ExerciseProgressOutput(action: .hold, nextWeight: nil, nextRepTarget: nil, nextAssistance: nil)
            }

            if metTargets {
                // Progress load
                let nextWeight = LoadRounding.rounded(lastW + inc, unit: weightUnit, equip: equipType)

                var nextAssist: Double? = nil
                if equipType == .machineAssistance {
                    let rule = ExerciseProgressionCatalog.shared.rule(for: normalizedName)
                    let assistStep = rule?.assistanceStep ?? rule?.weightIncrement ?? inc
                    let minAssist = rule?.minAssistance ?? 0
                    let base = input.lastTopSetWeight ?? lastW
                    let raw = base - assistStep
                    nextAssist = LoadRounding.rounded(max(minAssist, raw), unit: weightUnit, equip: .machineAssistance)
                }

                return ExerciseProgressOutput(
                    action: .progress,
                    nextWeight: nextWeight,
                    nextRepTarget: nil,
                    nextAssistance: nextAssist
                )
            } else {
                // Missed window slightly? hold. If persistent misses, you can regress:
                // Tune this policy later with trailing history – for now we hold.
                let nextWeight = LoadRounding.rounded(lastW, unit: weightUnit, equip: equipType)
                return ExerciseProgressOutput(
                    action: .hold,
                    nextWeight: nextWeight,
                    nextRepTarget: nil,
                    nextAssistance: nil
                )
            }

        case .isolation:
            // Rep-centric progression
            let step = baseIncrements.isolationRepStep

            if metTargets {
                // Add 1 rep to the target window (e.g., 8...10 -> 9...11)
                let newLower = input.targetReps.lowerBound + step
                let newUpper = input.targetReps.upperBound + step
                return ExerciseProgressOutput(
                    action: .progress,
                    nextWeight: nil,
                    nextRepTarget: newLower...newUpper,
                    nextAssistance: nil
                )
            } else {
                // Hold
                return ExerciseProgressOutput(
                    action: .hold,
                    nextWeight: nil,
                    nextRepTarget: input.targetReps,
                    nextAssistance: nil
                )
            }
        }
    }

    // --- BEGIN NEW CODE ---

    /// Computes the appropriate weight increment based on weight unit and optional override.
    private static func computeWeightIncrement(weightUnit: WeightUnit, override: Double?) -> Double {
        if let inc = override {
            return inc
        }
        switch weightUnit {
        case .lb:
            return 5.0
        case .kg:
            return 2.5
        }
    }

    /// Applies the progress direction to determine the resulting weight value
    private static func applyDirection(base: Double, delta: Double, direction: ProgressDirection, regress: Bool) -> Double {
        switch (direction, regress) {
        case (.increase, false):
            return base + delta
        case (.increase, true):
            return base - delta
        case (.decrease, false):
            return base - delta
        case (.decrease, true):
            return base + delta
        }
    }

    /// New decision function implementing progression catalog, miss streaks, and regressions
    static func decideNext(
        input: ExerciseProgressInput,
        weightUnit: WeightUnit,
        currentWeek: Int,
        currentDayIx: Int,
        modelContext: ModelContext,
        now: Date = Date()
    ) async -> (output: ExerciseProgressOutput, stored: EngineStoredNextTargetV2) {

        // Note: Week-1 gating is handled by callers (WorkoutSessionView).
        //       Week-2+ prefills are stored in ProgressionStoreV2 upon finish.

        #if DEBUG
        struct _ValidatorOnce { static var done = false }
        if !_ValidatorOnce.done { _ValidatorOnce.done = true; CatalogValidator.run() }
        #endif

        let normalizedName = ExerciseKey.normalize(input.exerciseName)

        // Fetch rule for exerciseName
        let rule = EngineProgressionCatalog.shared.rule(for: normalizedName)

        // Obtain last stored state for this mesocycleID and exerciseName
        let storedV2 = await ProgressionStoreV2.shared.getTarget(mesocycleID: input.mesocycleID, exercise: normalizedName)
        let lastStored: EngineStoredNextTargetV2? = {
            guard let s = storedV2 else { return nil }
            let repRange: ClosedRange<Int>
            if let lo = s.nextRepTargetLower, let hi = s.nextRepTargetUpper {
                repRange = lo...hi
            } else {
                repRange = input.targetReps
            }
            return EngineStoredNextTargetV2(
                mesocycleID: input.mesocycleID,
                exerciseName: normalizedName,
                progressKind: classifyKind(from: input.exerciseName),
                lastWeight: s.nextWeight,
                lastRepTarget: repRange,
                missStreak: s.missStreak,
                lastAction: {
                    switch s.lastAction {
                    case .some(.progressed): return .progress
                    case .some(.held): return .hold
                    case .some(.regressed): return .regress
                    case .none: return .hold
                    }
                }(),
                lastUpdatedAt: s.lastUpdatedAt ?? Date()
            )
        }()

        // Removed old Week gating block that returned early

        // Determine progression kind
        let progKind: ProgressionKind
        if let rule = rule {
            switch rule.progression {
            case .weight:
                progKind = .compound
            case .reps:
                progKind = .isolation
            default:
                progKind = classifyKind(from: input.exerciseName)
            }
        } else {
            progKind = classifyKind(from: input.exerciseName)
        }

        let context = DecisionContext(rule: rule, lastStored: lastStored)

        // Wave G: derive prior baseline top set if available (Week-2 should see Week-1)
        let priorTop = await priorTopSet(mesocycleID: input.mesocycleID, exerciseName: input.exerciseName, currentWeek: currentWeek, currentDayIx: currentDayIx, modelContext: modelContext)

        // Determine increments
        let weightIncrement = computeWeightIncrement(weightUnit: weightUnit, override: context.rule?.weightIncrement)
        let repIncrement = context.rule?.repIncrement ?? 1

        // Determine if targets are met
        let inWindow: Bool = {
            let reps = input.lastTopSetReps ?? priorTop?.reps
            guard let reps else { return false }
            return (lastStored?.lastRepTarget ?? input.targetReps).contains(reps)
        }()
        let metTargets = inWindow // && (input.achievedRIR ?? input.targetRIR) <= input.targetRIR

        // Determine miss streak and next action
        var missStreak = lastStored?.missStreak ?? 0
        var lastAction = lastStored?.lastAction ?? .hold

        var nextWeight: Double? = nil
        var nextRepTarget: ClosedRange<Int>? = nil
        var nextAssistance: Double? = nil
        let equipType = (EngineProgressionCatalog.shared.rule(for: normalizedName) as? ProgressionRule)?.equipType ?? .unknown
        switch progKind {
        case .compound:
            let lastWeight = input.lastTopSetWeight ?? lastStored?.lastWeight ?? priorTop?.weight

            guard let lastW = lastWeight else {
                // No prior weight, hold with no next weight
                lastAction = .hold
                missStreak = 0
                let output = ExerciseProgressOutput(action: lastAction, nextWeight: nil, nextRepTarget: nil, nextAssistance: nil)
                let stored = EngineStoredNextTargetV2(
                    mesocycleID: input.mesocycleID,
                    exerciseName: normalizedName,
                    progressKind: .compound,
                    lastWeight: nil,
                    lastRepTarget: input.targetReps,
                    missStreak: missStreak,
                    lastAction: lastAction,
                    lastUpdatedAt: now
                )
#if DEBUG
                let ruleEquip = (EngineProgressionCatalog.shared.rule(for: normalizedName) as? ProgressionRule)?.equipType ?? .unknown
                let ruleProg = EngineProgressionCatalog.shared.rule(for: normalizedName)?.progression ?? .unknown
                print("[EngineTrace] name=\(normalizedName), prog=\(ruleProg), equip=\(ruleEquip), unit=\(weightUnit), lastW=\(String(describing: input.lastTopSetWeight)), lastReps=\(String(describing: input.lastTopSetReps)), inc=\(weightIncrement), nextW=\(String(describing: output.nextWeight)), nextReps=\(String(describing: output.nextRepTarget)), action=\(lastAction.rawValue)")
#endif
                return (output, stored)
            }

            if metTargets {
                // Success: progress load, reset miss streak
                missStreak = 0
                lastAction = .progress
                let step = (equipType.machineFineSteps ? weightUnit.fineStep : weightUnit.coarseStep)
                let rawNext = applyDirection(base: lastW, delta: step, direction: context.progressDirection, regress: false)
                var roundedNext = LoadRounding.rounded(rawNext, unit: weightUnit, equip: equipType)
                // Ensure we don't round back to the same number; if so, bump one more step in the same direction
                if roundedNext == lastW {
                    let rawNext2 = applyDirection(base: rawNext, delta: step, direction: context.progressDirection, regress: false)
                    roundedNext = LoadRounding.rounded(rawNext2, unit: weightUnit, equip: equipType)
                }
                nextWeight = roundedNext

                // Optional assistance handling for machineAssistance equipType
                if equipType == .machineAssistance {
                    let legacyRule = EngineProgressionCatalog.shared.rule(for: normalizedName) as? ProgressionRule
                    let step = legacyRule?.assistanceStep ?? (rule?.weightIncrement ?? weightIncrement)
                    let minAssist = legacyRule?.minAssistance ?? 0
                    if let baseWeight = input.lastTopSetWeight ?? lastStored?.lastWeight {
                        let nextAssistRaw = applyDirection(base: baseWeight, delta: step, direction: .decrease, regress: false)
                        nextAssistance = LoadRounding.rounded(max(minAssist, nextAssistRaw), unit: weightUnit, equip: .machineAssistance)
                    }
                }
                nextRepTarget = nil
            } else {
                // Failure: increase miss streak
                missStreak += 1

                if missStreak == 1 {
                    // First miss: hold
                    lastAction = .hold
                    nextWeight = LoadRounding.rounded(lastW, unit: weightUnit, equip: equipType)
                    nextAssistance = nil
                    nextRepTarget = nil
                } else {
                    // Second or more miss: regress and reset miss streak
                    lastAction = .regress
                    nextWeight = LoadRounding.rounded(
                        applyDirection(base: lastW, delta: weightIncrement, direction: context.progressDirection, regress: true),
                        unit: weightUnit,
                        equip: equipType
                    )
                    nextAssistance = nil
                    nextRepTarget = nil
                    missStreak = 0
                }
            }

        case .isolation:
            let lastRepRange = lastStored?.lastRepTarget ?? input.targetReps

            if metTargets {
                // Success: progress reps and reset miss streak
                missStreak = 0
                lastAction = .progress

                let newLower = lastRepRange.lowerBound + repIncrement
                let newUpper = lastRepRange.upperBound + repIncrement
                nextRepTarget = newLower...newUpper
                nextWeight = nil
                nextAssistance = nil
            } else {
                // Failure: hold reps, increment miss streak
                missStreak += 1
                lastAction = .hold
                nextRepTarget = lastRepRange
                nextWeight = nil
                nextAssistance = nil
            }
        }

        let stored = EngineStoredNextTargetV2(
            mesocycleID: input.mesocycleID,
            exerciseName: normalizedName,
            progressKind: progKind,
            lastWeight: nextWeight ?? lastStored?.lastWeight ?? input.lastTopSetWeight,
            lastRepTarget: nextRepTarget ?? lastStored?.lastRepTarget ?? input.targetReps,
            missStreak: missStreak,
            lastAction: lastAction,
            lastUpdatedAt: now
        )

        // Persist stored state into ProgressionStoreV2
        let toPersist = StoredNextTargetV2(
            nextWeight: stored.lastWeight,
            nextRepTargetLower: stored.lastRepTarget.lowerBound,
            nextRepTargetUpper: stored.lastRepTarget.upperBound,
            missStreak: stored.missStreak,
            lastAction: {
                switch stored.lastAction {
                case .progress: return .progressed
                case .hold: return .held
                case .regress: return .regressed
                }
            }(),
            lastUpdatedAt: stored.lastUpdatedAt
        )
        await ProgressionStoreV2.shared.updateTarget(mesocycleID: input.mesocycleID, exercise: normalizedName) { target in
            target = toPersist
        }

        let output = ExerciseProgressOutput(action: lastAction, nextWeight: nextWeight, nextRepTarget: nextRepTarget, nextAssistance: nextAssistance)

#if DEBUG
        let ruleEquip = (EngineProgressionCatalog.shared.rule(for: normalizedName) as? ProgressionRule)?.equipType ?? .unknown
        let ruleProg = EngineProgressionCatalog.shared.rule(for: normalizedName)?.progression ?? .unknown
        print("[EngineTrace] name=\(normalizedName), prog=\(ruleProg), equip=\(ruleEquip), unit=\(weightUnit), lastW=\(String(describing: input.lastTopSetWeight)), lastReps=\(String(describing: input.lastTopSetReps)), inc=\(weightIncrement), nextW=\(String(describing: nextWeight)), nextReps=\(String(describing: nextRepTarget)), action=\(lastAction.rawValue)")
#endif

        return (output, stored)
    }

    // Test helpers

    internal static func roundedWeight(from raw: Double, unit: WeightUnit, equip: EquipType) -> Double {
        LoadRounding.rounded(raw, unit: unit, equip: equip)
    }

    internal static func nextAssistance(current: Double, step: Double, min: Double, unit: WeightUnit) -> Double {
        let raw = max(min, current - step)
        return LoadRounding.rounded(raw, unit: unit, equip: .machineAssistance)
    }

    internal static func carryOverReps(from sets: [(weight: Double, reps: Int)]) -> Int? {
        return sets.max(by: { $0.weight < $1.weight })?.reps
    }

    // --- END NEW CODE ---
}

