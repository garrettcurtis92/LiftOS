//
//  WorkoutSessionView.swift
//  LiftOS
//

import SwiftUI
import SwiftData

struct WorkoutSessionView: View {
    // Input
    var dayLabel: String? = nil
    private let preset: String
    let mesocycleID: UUID?
    let onGoToMesocycles: (() -> Void)?
    var onMesocycleCompleted: (() -> Void)? = nil

    // App-wide prefs used within view
    @AppStorage("weightUnit") private var weightUnit: WeightUnit = .lb
    @AppStorage("daysPerWeek") private var daysPerWeek: Int = 3
    @AppStorage("currentWeek") private var currentWeek: Int = 1
    @AppStorage("currentDayIx") private var currentDayIx: Int = 0
    @AppStorage("restTimerEnabled") private var restTimerEnabled: Bool = true
    @AppStorage("restTimerAutoStart") private var restTimerAutoStart: Bool = true
    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var activeMesocycle: Mesocycle? = nil

    // Session state
    @State private var session: WorkoutSession

    // UI state
    @State private var showRestTimer = false
    @State private var lastRestDuration: Int = 90
    @State private var completed: [UUID: [ExerciseSet]] = [:] // exercise.id -> sets
    @State private var lastSummary: SessionSummary?
    @State private var showCongrats = false
    @State private var sessionStart: Date? = nil

    @State private var errorMessage: String? = nil
    @State private var restRemaining: Int = 0
    @State private var restTimer: Timer? = nil
    //

    // Helper to show a full weekday name from currentDayIx (0-based)
    private func weekdayName(for ix: Int) -> String {
        // Start Monday as index 0
        let names = ["Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"]
        guard ix >= 0 && ix < names.count else { return "Day \(ix + 1)" }
        return names[ix]
    }

    private var sessionProgress: Double {
        let total = session.exercises.reduce(0) { $0 + max(1, $1.targetSets) }
        let done = session.exercises.reduce(0) { partial, ex in
            let sets = completed[ex.id] ?? []
            return partial + sets.filter { $0.done && $0.weight != nil && $0.reps != nil }.count
        }
        guard total > 0 else { return 0 }
        return min(1, Double(done) / Double(total))
    }
    
    // MARK: - Persistence helpers
    
    private func upsertSetLog(mesocycleID: UUID, week: Int, dayIx: Int, exerciseDisplayName: String, exerciseKey: String, setIndex: Int, weight: Double?, reps: Int?, done: Bool, unit: WeightUnit) {
        let _meso = mesocycleID
        let _week = week
        let _day = dayIx
        let _key = exerciseKey
        let _set = setIndex
        let d = FetchDescriptor<WorkoutLogEntry>(
            predicate: #Predicate { $0.mesocycleID == _meso && $0.week == _week && $0.dayIx == _day && $0.exerciseKey == _key && $0.setIndex == _set }
        )
        let existing = (try? modelContext.fetch(d)) ?? []
        if let e = existing.first {
            e.weight = weight
            e.reps = reps
            e.done = done
            e.updatedAt = Date()
            e.exerciseName = exerciseDisplayName // keep display fresh if it changed
            e.unit = unit
        } else {
            let rec = WorkoutLogEntry(
                mesocycleID: mesocycleID,
                week: week,
                dayIx: dayIx,
                exerciseName: exerciseDisplayName,
                exerciseKey: exerciseKey,
                setIndex: setIndex,
                weight: weight,
                reps: reps,
                done: done,
                unit: unit
            )
            modelContext.insert(rec)
        }
        try? modelContext.save()
    }
    
    private func deleteSetLog(mesocycleID: UUID, week: Int, dayIx: Int, exerciseKey: String, setIndex: Int) {
        let _meso = mesocycleID
        let _week = week
        let _day = dayIx
        let _key = exerciseKey
        let _set = setIndex
        let d = FetchDescriptor<WorkoutLogEntry>(
            predicate: #Predicate { $0.mesocycleID == _meso && $0.week == _week && $0.dayIx == _day && $0.exerciseKey == _key && $0.setIndex == _set }
        )
        if let existing = try? modelContext.fetch(d) {
            for e in existing { modelContext.delete(e) }
            try? modelContext.save()
        }
    }

    init(dayLabel: String? = nil, preset: String, mesocycleID: UUID? = nil, onGoToMesocycles: (() -> Void)? = nil, onMesocycleCompleted: (() -> Void)? = nil) {
        self.dayLabel = dayLabel
        self.preset = preset
        self.mesocycleID = mesocycleID
        self.onGoToMesocycles = onGoToMesocycles
        self.onMesocycleCompleted = onMesocycleCompleted
        self._session = State(initialValue: WorkoutSession(title: preset, exercises: []))
    }

    var body: some View {
        if activeMesocycle == nil || session.exercises.isEmpty {
            ContentUnavailableView {
                Label(
                    activeMesocycle == nil ? "No Active Mesocycle" : "No Workout Scheduled",
                    systemImage: activeMesocycle == nil ? "chart.line.uptrend.xyaxis" : "calendar"
                )
            } description: {
                if activeMesocycle != nil {
                    Text("This day has no workouts in the current mesocycle.")
                }
            } actions: {
                if activeMesocycle == nil {
                    Button {
                        Haptics.tap()
                        if let onGoToMesocycles {
                            onGoToMesocycles()
                        } else {
                            dismiss()
                        }
                    } label: {
                        Label("Go to Mesocycles", systemImage: "chart.line.uptrend.xyaxis")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .task {
                if let id = mesocycleID {
                    // Fetch Mesocycle by id
                    let descriptor = FetchDescriptor<Mesocycle>(predicate: #Predicate { $0.id == id })
                    if let found = try? modelContext.fetch(descriptor).first {
                        activeMesocycle = found
                        syncNextPositionFromMeso()
                        rebuildSessionForCurrentPosition()
                    }
                }
                let target = MesocycleRules.rirTarget(forWeek: currentWeek)
                for i in session.exercises.indices { session.exercises[i].rirTarget = target }

                if let id = mesocycleID {
                    for i in session.exercises.indices {
                        let name = session.exercises[i].name
                        let hasBL = await MesocycleProgressionEngine.hasBaseline(mesocycleID: id, exerciseName: name, currentWeek: currentWeek, currentDayIx: currentDayIx, modelContext: modelContext)
                        let priorCount = await MesocycleProgressionEngine.priorSessionCount(mesocycleID: id, exerciseName: name, currentWeek: currentWeek, currentDayIx: currentDayIx, modelContext: modelContext)
                        var didPrefill = false
                        if currentWeek >= 2 {
                            // Preferred: read precomputed targets from v2 store
                            if let v2 = await ProgressionStoreV2.shared.getTarget(mesocycleID: id, exercise: name) {
                                session.exercises[i].suggestedNextWeight = v2.nextWeight
                                session.exercises[i].suggestedNextRepTargetLower = v2.nextRepTargetLower
                                session.exercises[i].suggestedNextRepTargetUpper = v2.nextRepTargetUpper
                                didPrefill = (v2.nextWeight != nil) || (v2.nextRepTargetLower != nil) || (v2.nextRepTargetUpper != nil)
                            } else if let next = ProgressionStore.shared.get(mesocycleID: id, exerciseName: name) {
                                // Legacy fallback (v1)
                                session.exercises[i].suggestedNextWeight = next.nextWeight
                                session.exercises[i].suggestedNextRepTargetLower = next.nextRepTargetLower
                                session.exercises[i].suggestedNextRepTargetUpper = next.nextRepTargetUpper
                                didPrefill = (next.nextWeight != nil) || (next.nextRepTargetLower != nil) || (next.nextRepTargetUpper != nil)
                            } else {
                                // On-the-fly fallback when no stored targets are available
                                let kind = MesocycleProgressionEngine.classifyKind(from: name)
                                let isCompound = (kind == .compound)
                                let input = ExerciseProgressInput(
                                    mesocycleID: id,
                                    exerciseName: name,
                                    isCompound: isCompound,
                                    lastTopSetWeight: nil,
                                    lastTopSetReps: nil,
                                    targetReps: 8...10,
                                    targetRIR: session.exercises[i].rirTarget,
                                    achievedRIR: nil
                                )
                                let res = await MesocycleProgressionEngine.decideNext(
                                    input: input,
                                    weightUnit: weightUnit,
                                    currentWeek: currentWeek,
                                    currentDayIx: currentDayIx,
                                    modelContext: modelContext
                                )
                                let out = res.output
                                session.exercises[i].suggestedNextWeight = out.nextWeight
                                session.exercises[i].suggestedNextRepTargetLower = out.nextRepTarget?.lowerBound
                                session.exercises[i].suggestedNextRepTargetUpper = out.nextRepTarget?.upperBound
                                didPrefill = (out.nextWeight != nil) || (out.nextRepTarget != nil)
                            }
                        }
#if DEBUG
                        print("[PrefillTrace] week=\(currentWeek) day=\(currentDayIx) exercise=\(name) hasBaseline=\(hasBL) priorSessions=\(priorCount) didPrefill=\(didPrefill)")
#endif
                    }
                }
            }
        } else {
            VStack(spacing: 0) {
                ExerciseListView(
                    exercises: session.exercises,
                    completed: completed,
                    weightUnit: weightUnit,
                    lastRepsProvider: { ex in lastRepsDict(for: ex) },
                    hasBaseline: { ex in
                        ex.suggestedNextWeight != nil || ex.suggestedNextRepTargetLower != nil || ex.suggestedNextRepTargetUpper != nil
                    },
                    onAddSet: { handleAddSet(for: $0) },
                    onSkipSet: { ex, idx in handleSkipSet(for: ex, index: idx) },
                    onDeleteSet: { ex, idx in handleDeleteSet(for: ex, index: idx) },
                    onCommitInline: { ex, idx, w, r, checked in handleCommitInline(for: ex, index: idx, weight: w, reps: r, checked: checked) }
                )
            }
            .scrollContentBackground(.hidden)
            .background(WorkoutBackground())
            .scrollDismissesKeyboard(.interactively)
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .safeAreaInset(edge: .top) {
                SessionHeaderBar(
                    week: currentWeek,
                    dayLabel: dayLabel ?? weekdayName(for: currentDayIx),
                    sessionProgress: sessionProgress,
                    showRestTimer: $showRestTimer,
                    onPickRestDuration: { secs in
                        lastRestDuration = secs
                        if restTimerEnabled {
                            if restTimerAutoStart {
                                startRestCountdown(seconds: secs)
                            } else {
                                showRestTimer = true
                            }
                        }
                    }
                )
                .overlay(alignment: .bottomTrailing) {
                    if restRemaining > 0 {
                        Text("\(restRemaining)s")
                            .font(.caption.monospacedDigit())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(.thinMaterial))
                            .padding(.trailing, 12)
                            .padding(.bottom, 6)
                            .accessibilityLabel("Rest remaining \(restRemaining) seconds")
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(activeMesocycle?.name ?? session.title)
            // Bottom finish bar (only when all sets done)
            .safeAreaInset(edge: .bottom) {
                if stableAllSetsLogged && !showRestTimer {
                    VStack { 
                        PrimaryButton(title: "Finish Session", systemIcon: "checkmark.circle.fill", style: .success) {
                            Haptics.success()
                            finishSession()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial)
                }
            }
            // Apply week-based RIR on appear
            .onAppear {
                LoggingMigrator.runIfNeeded(modelContext)
                if let id = mesocycleID {
                    // Fetch Mesocycle by id
                    let descriptor = FetchDescriptor<Mesocycle>(predicate: #Predicate { $0.id == id })
                    if let found = try? modelContext.fetch(descriptor).first {
                        activeMesocycle = found
                        // Ensure mesocycle starts on the first day until completed
                        let firstDayDesc = FetchDescriptor<MesoCompletion>(predicate: #Predicate {
                            $0.mesocycleID == id && $0.week == 1 && $0.dayIx == 0
                        })
                        let firstDayDone = (try? modelContext.fetch(firstDayDesc))?.isEmpty == false
                        if !firstDayDone {
                            currentWeek = 1
                            currentDayIx = 0
                        }
                        // Clamp the selected day to the configured and available range
                        let maxDayIxFromPlan = max(0, min(found.days.count - 1, daysPerWeek - 1))
                        if currentDayIx > maxDayIxFromPlan {
                            currentDayIx = maxDayIxFromPlan
                        }
                        // Build session from mesocycle snapshot if available, otherwise fall back to relational days
                        let dayIx = currentDayIx
                        if let snap = found.planSnapshot, dayIx < snap.count {
                            let day = snap[dayIx]
                            let items: [ExerciseItem] = day.exercises.map { tmpl in
                                ExerciseItem(
                                    name: tmpl.exerciseDisplayName,
                                    targetSets: tmpl.defaultSets,
                                    rirTarget: MesocycleRules.rirTarget(forWeek: currentWeek),
                                    typeLabel: ExerciseTypeLabelProvider.typeLabel(forDisplayName: tmpl.exerciseDisplayName)
                                )
                            }
                            session = WorkoutSession(title: found.name, exercises: items)
                        } else {
                            let daysSorted = found.days.sorted(by: { $0.index < $1.index })
                            let day = daysSorted[dayIx]
                            let items: [ExerciseItem] = day.selections.compactMap { sel in
                                if let ex = sel.exercise {
                                    return ExerciseItem(name: ex.name, targetSets: 3, rirTarget: MesocycleRules.rirTarget(forWeek: currentWeek), typeLabel: ExerciseTypeLabelProvider.typeLabel(from: ex))
                                } else {
                                    return nil
                                }
                            }
                            session = WorkoutSession(title: found.name, exercises: items)
                        }
                    }
                }
                let target = MesocycleRules.rirTarget(forWeek: currentWeek)
                for i in session.exercises.indices { session.exercises[i].rirTarget = target }
                
                if let id = mesocycleID {
                    Task {
                        for i in session.exercises.indices {
                            let name = session.exercises[i].name
                            let hasBL = await MesocycleProgressionEngine.hasBaseline(mesocycleID: id, exerciseName: name, currentWeek: currentWeek, currentDayIx: currentDayIx, modelContext: modelContext)
                            let priorCount = await MesocycleProgressionEngine.priorSessionCount(mesocycleID: id, exerciseName: name, currentWeek: currentWeek, currentDayIx: currentDayIx, modelContext: modelContext)
                            var didPrefill = false
                            if currentWeek >= 2 {
                                // Preferred: read precomputed targets from v2 store
                                if let v2 = await ProgressionStoreV2.shared.getTarget(mesocycleID: id, exercise: name) {
                                    session.exercises[i].suggestedNextWeight = v2.nextWeight
                                    session.exercises[i].suggestedNextRepTargetLower = v2.nextRepTargetLower
                                    session.exercises[i].suggestedNextRepTargetUpper = v2.nextRepTargetUpper
                                    didPrefill = (v2.nextWeight != nil) || (v2.nextRepTargetLower != nil) || (v2.nextRepTargetUpper != nil)
                                } else if let next = ProgressionStore.shared.get(mesocycleID: id, exerciseName: name) {
                                    // Legacy fallback (v1)
                                    session.exercises[i].suggestedNextWeight = next.nextWeight
                                    session.exercises[i].suggestedNextRepTargetLower = next.nextRepTargetLower
                                    session.exercises[i].suggestedNextRepTargetUpper = next.nextRepTargetUpper
                                    didPrefill = (next.nextWeight != nil) || (next.nextRepTargetLower != nil) || (next.nextRepTargetUpper != nil)
                                } else {
                                    // On-the-fly fallback when no stored targets are available
                                    let kind = MesocycleProgressionEngine.classifyKind(from: name)
                                    let isCompound = (kind == .compound)
                                    let input = ExerciseProgressInput(
                                        mesocycleID: id,
                                        exerciseName: name,
                                        isCompound: isCompound,
                                        lastTopSetWeight: nil,
                                        lastTopSetReps: nil,
                                        targetReps: 8...10,
                                        targetRIR: session.exercises[i].rirTarget,
                                        achievedRIR: nil
                                    )
                                    let res = await MesocycleProgressionEngine.decideNext(
                                        input: input,
                                        weightUnit: weightUnit,
                                        currentWeek: currentWeek,
                                        currentDayIx: currentDayIx,
                                        modelContext: modelContext
                                    )
                                    let out = res.output
                                    session.exercises[i].suggestedNextWeight = out.nextWeight
                                    session.exercises[i].suggestedNextRepTargetLower = out.nextRepTarget?.lowerBound
                                    session.exercises[i].suggestedNextRepTargetUpper = out.nextRepTarget?.upperBound
                                    didPrefill = (out.nextWeight != nil) || (out.nextRepTarget != nil)
                                }
                            }
#if DEBUG
                            print("[PrefillTrace] week=\(currentWeek) day=\(currentDayIx) exercise=\(name) hasBaseline=\(hasBL) priorSessions=\(priorCount) didPrefill=\(didPrefill)")
#endif
                        }
                    }
                    // One-time migration from v1 -> v2
                    Task {
                        await ProgressionStoreV2.shared.migrateFromV1IfNeeded()
                    }

                    // Load any previously logged sets for this session
                    loadLoggedSessionIfAvailable()
                }
            }
            .sheet(item: $lastSummary, onDismiss: { handlePostSummaryFlow() }) { s in
                NavigationStack { SessionSummaryView(summary: s) }
            }
            .sheet(isPresented: $showCongrats) {
                MesoCompletionCongratsView(mesocycleName: activeMesocycle?.name ?? "Mesocycle") {
                    showCongrats = false
                    onMesocycleCompleted?()
                }
            }
            .sheet(isPresented: $showRestTimer) {
                RestTimerView(seconds: lastRestDuration) {
                    showRestTimer = false
                }
            }
            .onChange(of: restTimerEnabled) { oldValue, newValue in
                if !newValue {
                    showRestTimer = false
                    cancelRestCountdown()
                }
            }
            .onDisappear {
                cancelRestCountdown()
            }
            .alert("Incomplete Session", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    // MARK: - Derived
    private var mesocycleName: String {
        // If we add naming later, pull from ActiveMesocycleStore; for now use a friendly placeholder.
        return "Active Mesocycle"
    }
    private var allSetsLogged: Bool {
        for ex in session.exercises {
            // Require indices 1...targetSets all present with weight & reps and done
            let sets = completed[ex.id] ?? []
            let byIndex = Dictionary(uniqueKeysWithValues: sets.map { ($0.index, $0) })
            guard ex.targetSets > 0 else { return false }
            for idx in 1...ex.targetSets {
                guard let s = byIndex[idx], s.done, s.weight != nil, s.reps != nil else { return false }
            }
        }
        return true
    }
    private var stableAllSetsLogged: Bool {
        guard let meso = mesocycleID, let activeMesocycle else { return allSetsLogged }
        let _meso = meso
        let _week = currentWeek
        let _day = currentDayIx

        // Determine planned items for the day using snapshot first
        let planned: [(key: String, sets: Int)] = {
            if let snap = activeMesocycle.planSnapshot, currentDayIx < snap.count {
                let d = snap[currentDayIx]
                return d.exercises.map { (PlanKey.normalize($0.exerciseDisplayName), $0.defaultSets) }
            } else if currentDayIx < activeMesocycle.days.count {
                let daysSorted = activeMesocycle.days.sorted(by: { $0.index < $1.index })
                let day = daysSorted[currentDayIx]
                return day.selections.compactMap { sel in
                    if let ex = sel.exercise { return (PlanKey.normalize(ex.name), 3) }
                    return nil
                }
            } else { return [] }
        }()

        // Fetch all logs for the day
        let d = FetchDescriptor<WorkoutLogEntry>(predicate: #Predicate { $0.mesocycleID == _meso && $0.week == _week && $0.dayIx == _day })
        let logs = (try? modelContext.fetch(d)) ?? []
        let grouped = Dictionary(grouping: logs, by: { $0.exerciseKey })

        for (key, sets) in planned {
            let entries = grouped[key] ?? []
            guard sets > 0 else { return false }
            let byIx = Dictionary(uniqueKeysWithValues: entries.map { ($0.setIndex, $0) })
            for idx in 1...sets {
                guard let e = byIx[idx], e.done, e.weight != nil, e.reps != nil else { return false }
            }
        }
        return !planned.isEmpty
    }
    
    private struct LoggedSet: Codable {
        var index: Int
        var weight: Double?
        var reps: Int?
        var rir: Int?
        var done: Bool
    }

    private func lastRepsDict(for exercise: ExerciseItem) -> [Int: Int] {
        var dict: [Int: Int] = [:]
        if let lo = exercise.suggestedNextRepTargetLower, exercise.targetSets > 0 {
            for i in 1...exercise.targetSets {
                dict[i] = lo
            }
        }
        if let arr = completed[exercise.id] {
            for s in arr {
                if let r = s.reps {
                    dict[s.index] = r
                }
            }
        }
        return dict
    }

    private func loadLoggedSessionIfAvailable() {
        // Load logs stored per set for this week/day and map them into `completed`
        let _week = currentWeek
        let _day = currentDayIx

        if let _meso = mesocycleID {
            let d = FetchDescriptor<WorkoutLogEntry>(predicate: #Predicate { $0.mesocycleID == _meso && $0.week == _week && $0.dayIx == _day })
            let logs = (try? modelContext.fetch(d)) ?? []
            guard !logs.isEmpty else { return }

            let byKey = Dictionary(grouping: logs, by: { $0.exerciseKey })

            for i in session.exercises.indices {
                let nameKey = PlanKey.normalize(session.exercises[i].name)
                guard let entries = byKey[nameKey] else { continue }
                // Map to ExerciseSet using setIndex/reps/weight
                let mapped: [ExerciseSet] = entries.map { e in
                    ExerciseSet(index: e.setIndex, weight: e.weight, reps: e.reps, rir: nil, done: e.done)
                }
                completed[session.exercises[i].id] = mapped
                if let maxIx = mapped.map({ $0.index }).max(), maxIx > session.exercises[i].targetSets {
                    session.exercises[i].targetSets = maxIx
                }
            }
        } else {
            // Fallback for sessions without a mesocycle context
            let d = FetchDescriptor<WorkoutLogEntry>(predicate: #Predicate { $0.week == _week && $0.dayIx == _day })
            let logs = (try? modelContext.fetch(d)) ?? []
            guard !logs.isEmpty else { return }

            let byKey = Dictionary(grouping: logs, by: { $0.exerciseKey })

            for i in session.exercises.indices {
                let nameKey = PlanKey.normalize(session.exercises[i].name)
                guard let entries = byKey[nameKey] else { continue }
                let mapped: [ExerciseSet] = entries.map { e in
                    ExerciseSet(index: e.setIndex, weight: e.weight, reps: e.reps, rir: nil, done: e.done)
                }
                completed[session.exercises[i].id] = mapped
                if let maxIx = mapped.map({ $0.index }).max(), maxIx > session.exercises[i].targetSets {
                    session.exercises[i].targetSets = maxIx
                }
            }
        }
    }
    
    private func startRestCountdown(seconds: Int) {
        restTimer?.invalidate()
        restRemaining = seconds
        showRestTimer = false
        restTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { t in
            if UIAccessibility.isReduceMotionEnabled {
                // No tick animations, just decrement
            }
            restRemaining -= 1
            if restRemaining <= 0 {
                t.invalidate()
                restRemaining = 0
                if hapticsEnabled { Haptics.tap() }
            }
        }
    }

    private func cancelRestCountdown() {
        restTimer?.invalidate()
        restTimer = nil
        restRemaining = 0
    }

    // MARK: - Actions
    private func finishSession() {
        // Defensive check: ensure all sets are fully logged
        guard allSetsLogged else {
            #if canImport(UIKit)
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            #endif
            errorMessage = "Please complete all sets (weight and reps) before finishing."
            return
        }

        let setsFlat = session.exercises.flatMap { ex in
            (completed[ex.id] ?? []).map { CompletedSet(from: $0, exerciseName: ex.name) }
        }
        let built = SummaryBuilder.build(title: session.title, date: Date(), sets: setsFlat, sessionStart: sessionStart)
        lastSummary = built.summary
        
        // Logs are persisted per-set on commit; nothing to do here for logs.
        
        if let id = mesocycleID {
            let completion = MesoCompletion(mesocycleID: id, week: currentWeek, dayIx: currentDayIx, completedAt: Date())
            modelContext.insert(completion)
            try? modelContext.save()
        }
        Haptics.success()
        
        guard let mesoID = mesocycleID else { return }

        Task {
            for ex in session.exercises {
                let name = ex.name
                let kind = MesocycleProgressionEngine.classifyKind(from: name)
                let isCompound = (kind == .compound)

                // Derive a "top set" from what the user logged this session
                let logged = (completed[ex.id] ?? [])
                let top = logged.max(by: { (a, b) in
                    // choose the heavier set; if nil, treat as 0
                    (a.weight ?? 0) < (b.weight ?? 0)
                })

                let lastWeight = top?.weight
                let lastReps   = top?.reps

                // Require a valid top set (both weight and reps) to generate next targets
                guard let validWeight = lastWeight, let validReps = lastReps else {
                    continue
                }

                // You can encode your current rep target window here (e.g., 8...10)
                // If you don’t have a per-ex target yet, pick a reasonable window for your program:
                let currentRepWindow: ClosedRange<Int> = 8...10

                let input = ExerciseProgressInput(
                    mesocycleID: mesoID,
                    exerciseName: name,
                    isCompound: isCompound,
                    lastTopSetWeight: validWeight,
                    lastTopSetReps: validReps,
                    targetReps: currentRepWindow,
                    targetRIR: ex.rirTarget,
                    achievedRIR: nil // plug in when you start collecting it
                )

                let res = await MesocycleProgressionEngine.decideNext(
                    input: input,
                    weightUnit: weightUnit,
                    currentWeek: currentWeek,
                    currentDayIx: currentDayIx,
                    modelContext: modelContext
                )
                let out = res.output

                // Choose next rep hint: never decrease below lastReps if available
                var desiredReps: Int? = nil
                if let lower = out.nextRepTarget?.lowerBound {
                    desiredReps = max(validReps, lower)
                } else {
                    desiredReps = validReps
                }

                if let r = desiredReps {
                    await ProgressionStoreV2.shared.updateTarget(mesocycleID: mesoID, exercise: name) { target in
                        target.nextRepTargetLower = r
                        target.nextRepTargetUpper = r
                    }
                }

                // Persist for backward compatibility (v1). v2 persistence occurs inside decideNext and was updated above.
                var stored = StoredNextTarget(
                    nextWeight: out.nextWeight,
                    nextRepTargetLower: out.nextRepTarget?.lowerBound,
                    nextRepTargetUpper: out.nextRepTarget?.upperBound
                )
                if let r = desiredReps {
                    stored.nextRepTargetLower = r
                    stored.nextRepTargetUpper = r
                }
                ProgressionStore.shared.set(mesocycleID: mesoID, exerciseName: name, next: stored)
            }
        }
    }

    private func syncNextPositionFromMeso() {
        guard let id = mesocycleID, let activeMesocycle else { return }

        // Fetch all completions for this mesocycle
        let descriptor = FetchDescriptor<MesoCompletion>(predicate: #Predicate { $0.mesocycleID == id })
        let completions = (try? modelContext.fetch(descriptor)) ?? []

        // Determine the maximum valid day index based on the plan and user setting
        let maxDayIxFromPlan = max(0, min(activeMesocycle.days.count - 1, daysPerWeek - 1))

        // If nothing has been completed yet, start at week 1, day 0
        guard !completions.isEmpty else {
            currentWeek = 1
            currentDayIx = 0
            return
        }

        // Find the last completed (week, dayIx)
        let sorted = completions.sorted { a, b in
            if a.week == b.week { return a.dayIx < b.dayIx }
            return a.week < b.week
        }

        if let last = sorted.last {
            var nextWeek = last.week
            var nextDay = last.dayIx + 1

            // Advance week if we've reached the end of the week's days
            if nextDay > maxDayIxFromPlan {
                nextDay = 0
                nextWeek += 1
            }

            // If we've exceeded the mesocycle length, clamp to the last valid position
            if nextWeek > activeMesocycle.weekCount {
                currentWeek = activeMesocycle.weekCount
                currentDayIx = maxDayIxFromPlan
            } else {
                currentWeek = nextWeek
                currentDayIx = nextDay
            }
        }
    }

    private func rebuildSessionForCurrentPosition() {
        guard let activeMesocycle else { return }
        completed = [:]
        lastSummary = nil
        sessionStart = nil
        if let snap = activeMesocycle.planSnapshot, currentDayIx < snap.count {
            let day = snap[currentDayIx]
            let items: [ExerciseItem] = day.exercises.map { tmpl in
                ExerciseItem(
                    name: tmpl.exerciseDisplayName,
                    targetSets: tmpl.defaultSets,
                    rirTarget: MesocycleRules.rirTarget(forWeek: currentWeek),
                    typeLabel: ExerciseTypeLabelProvider.typeLabel(forDisplayName: tmpl.exerciseDisplayName)
                )
            }
            session = WorkoutSession(title: activeMesocycle.name, exercises: items)
        } else if currentDayIx < activeMesocycle.days.count {
            let daysSorted = activeMesocycle.days.sorted(by: { $0.index < $1.index })
            let day = daysSorted[currentDayIx]
            let items: [ExerciseItem] = day.selections.compactMap { sel in
                if let ex = sel.exercise {
                    return ExerciseItem(name: ex.name, targetSets: 3, rirTarget: MesocycleRules.rirTarget(forWeek: currentWeek), typeLabel: ExerciseTypeLabelProvider.typeLabel(from: ex))
                } else { return nil }
            }
            session = WorkoutSession(title: activeMesocycle.name, exercises: items)
        } else {
            session = WorkoutSession(title: preset, exercises: [])
        }
        let target = MesocycleRules.rirTarget(forWeek: currentWeek)
        for i in session.exercises.indices { session.exercises[i].rirTarget = target }
        
        if let id = mesocycleID {
            Task {
                for i in session.exercises.indices {
                    let name = session.exercises[i].name
                    let hasBL = await MesocycleProgressionEngine.hasBaseline(mesocycleID: id, exerciseName: name, currentWeek: currentWeek, currentDayIx: currentDayIx, modelContext: modelContext)
                    let priorCount = await MesocycleProgressionEngine.priorSessionCount(mesocycleID: id, exerciseName: name, currentWeek: currentWeek, currentDayIx: currentDayIx, modelContext: modelContext)
                    var didPrefill = false
                    if currentWeek >= 2 {
                        // Preferred: read precomputed targets from v2 store
                        if let v2 = await ProgressionStoreV2.shared.getTarget(mesocycleID: id, exercise: name) {
                            session.exercises[i].suggestedNextWeight = v2.nextWeight
                            session.exercises[i].suggestedNextRepTargetLower = v2.nextRepTargetLower
                            session.exercises[i].suggestedNextRepTargetUpper = v2.nextRepTargetUpper
                            didPrefill = (v2.nextWeight != nil) || (v2.nextRepTargetLower != nil) || (v2.nextRepTargetUpper != nil)
                        } else if let next = ProgressionStore.shared.get(mesocycleID: id, exerciseName: name) {
                            session.exercises[i].suggestedNextWeight = next.nextWeight
                            session.exercises[i].suggestedNextRepTargetLower = next.nextRepTargetLower
                            session.exercises[i].suggestedNextRepTargetUpper = next.nextRepTargetUpper
                            didPrefill = (next.nextWeight != nil) || (next.nextRepTargetLower != nil) || (next.nextRepTargetUpper != nil)
                        } else {
                            // On-the-fly fallback when no stored targets are available
                            let kind = MesocycleProgressionEngine.classifyKind(from: name)
                            let isCompound = (kind == .compound)
                            let input = ExerciseProgressInput(
                                mesocycleID: id,
                                exerciseName: name,
                                isCompound: isCompound,
                                lastTopSetWeight: nil,
                                lastTopSetReps: nil,
                                targetReps: 8...10,
                                targetRIR: session.exercises[i].rirTarget,
                                achievedRIR: nil
                            )
                            let res = await MesocycleProgressionEngine.decideNext(
                                input: input,
                                weightUnit: weightUnit,
                                currentWeek: currentWeek,
                                currentDayIx: currentDayIx,
                                modelContext: modelContext
                            )
                            let out = res.output
                            session.exercises[i].suggestedNextWeight = out.nextWeight
                            session.exercises[i].suggestedNextRepTargetLower = out.nextRepTarget?.lowerBound
                            session.exercises[i].suggestedNextRepTargetUpper = out.nextRepTarget?.upperBound
                            didPrefill = (out.nextWeight != nil) || (out.nextRepTarget != nil)
                        }
                    }
#if DEBUG
                    print("[PrefillTrace] week=\(currentWeek) day=\(currentDayIx) exercise=\(name) hasBaseline=\(hasBL) priorSessions=\(priorCount) didPrefill=\(didPrefill)")
#endif
                }
            }
        }
        // Load any previously logged sets for this rebuilt position
        loadLoggedSessionIfAvailable()
    }

    private func handlePostSummaryFlow() {
        // Clear the presented summary item
        lastSummary = nil

        // If we're working within a mesocycle, advance to the next position and optionally show completion
        guard let activeMesocycle else { return }

        // Determine if the session we just finished was the final day of the final week
        let maxDayIxFromPlan = max(0, min(activeMesocycle.days.count - 1, daysPerWeek - 1))
        let justFinishedFinalSession = (currentWeek >= activeMesocycle.weekCount) && (currentDayIx >= maxDayIxFromPlan)

        // Move to the next target (week/day) and rebuild the session
        syncNextPositionFromMeso()
        rebuildSessionForCurrentPosition()

        // If the mesocycle is complete, present congrats
        if justFinishedFinalSession {
            showCongrats = true
        }
    }

    // MARK: - Exercise Set Handlers
    private func handleAddSet(for exercise: ExerciseItem) {
        if let i = session.exercises.firstIndex(where: { $0.id == exercise.id }) {
            session.exercises[i].targetSets += 1
        }
    }
    private func handleSkipSet(for exercise: ExerciseItem, index: Int) {
        let exID = exercise.id
        var arr = completed[exID, default: []]
        if arr.firstIndex(where: { $0.index == index }) == nil {
            arr.append(ExerciseSet(index: index, weight: nil, reps: nil, rir: nil, done: true))
        }
        completed[exID] = arr
        
        if let _meso = mesocycleID {
            let key = PlanKey.normalize(exercise.name)
            upsertSetLog(mesocycleID: _meso, week: currentWeek, dayIx: currentDayIx, exerciseDisplayName: exercise.name, exerciseKey: key, setIndex: index, weight: nil, reps: nil, done: true, unit: weightUnit)
        }
    }
    private func handleDeleteSet(for exercise: ExerciseItem, index: Int) {
        let exID = exercise.id
        if var arr = completed[exID] { arr.removeAll { $0.index == index }; completed[exID] = arr }
        if let i = session.exercises.firstIndex(where: { $0.id == exercise.id }) {
            if index == session.exercises[i].targetSets, session.exercises[i].targetSets > 1 {
                session.exercises[i].targetSets -= 1
            }
        }
        if let _meso = mesocycleID {
            let key = PlanKey.normalize(exercise.name)
            deleteSetLog(mesocycleID: _meso, week: currentWeek, dayIx: currentDayIx, exerciseKey: key, setIndex: index)
        }
    }
    private func handleCommitInline(for exercise: ExerciseItem, index: Int, weight: Double?, reps: Int?, checked: Bool) {
        if sessionStart == nil { sessionStart = Date() }
        let exID = exercise.id
        var arr = completed[exID, default: []]
        let newSet = ExerciseSet(index: index, weight: weight, reps: reps, rir: nil, done: checked)
        if let pos = arr.firstIndex(where: { $0.index == index }) { arr[pos] = newSet } else { arr.append(newSet) }
        completed[exID] = arr
        if checked && restTimerEnabled {
            lastRestDuration = 90
            if restTimerAutoStart {
                startRestCountdown(seconds: lastRestDuration)
            } else {
                showRestTimer = true
            }
        }
        if let _meso = mesocycleID {
            let key = PlanKey.normalize(exercise.name)
            upsertSetLog(mesocycleID: _meso, week: currentWeek, dayIx: currentDayIx, exerciseDisplayName: exercise.name, exerciseKey: key, setIndex: index, weight: weight, reps: reps, done: checked, unit: weightUnit)
        }
    }

    // MARK: - Session factory
    private static func makeSession(title: String, mesocycleID: UUID? = nil) -> WorkoutSession {
        var ex: [ExerciseItem]
        switch title.lowercased() {
        case "push": ex = [ ExerciseItem(name: "Bench Press", targetSets: 4, rirTarget: 3), ExerciseItem(name: "Overhead Press", targetSets: 3, rirTarget: 3), ExerciseItem(name: "Incline DB Press", targetSets: 3, rirTarget: 3) ]
        case "pull": ex = [ ExerciseItem(name: "Deadlift", targetSets: 3, rirTarget: 3), ExerciseItem(name: "Barbell Row", targetSets: 4, rirTarget: 3), ExerciseItem(name: "Lat Pulldown", targetSets: 3, rirTarget: 3) ]
        case "legs": ex = [ ExerciseItem(name: "Back Squat", targetSets: 4, rirTarget: 3), ExerciseItem(name: "Leg Press", targetSets: 3, rirTarget: 3), ExerciseItem(name: "Leg Curl", targetSets: 3, rirTarget: 3) ]
        default: ex = [ ExerciseItem(name: "DB Curl", targetSets: 3, rirTarget: 3), ExerciseItem(name: "Triceps Pushdown", targetSets: 3, rirTarget: 3) ]
        }
        if let id = mesocycleID {
            Task {
                for i in ex.indices {
                    let name = ex[i].name
                    let v2 = await ProgressionStoreV2.shared.getTarget(mesocycleID: id, exercise: name)
                    if let v2 {
                        ex[i].suggestedNextWeight = v2.nextWeight
                        ex[i].suggestedNextRepTargetLower = v2.nextRepTargetLower
                        ex[i].suggestedNextRepTargetUpper = v2.nextRepTargetUpper
                    } else if let next = ProgressionStore.shared.get(mesocycleID: id, exerciseName: name) {
                        ex[i].suggestedNextWeight = next.nextWeight
                        ex[i].suggestedNextRepTargetLower = next.nextRepTargetLower
                        ex[i].suggestedNextRepTargetUpper = next.nextRepTargetUpper
                    }
                }
            }
        }
        return WorkoutSession(title: title, exercises: ex)
    }
}

struct WorkoutBackground: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        LinearGradient(
            colors: scheme == .dark
                ? [Color.black, Color(white: 0.08)]
                : [Color(white: 0.98), Color(white: 0.94)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

fileprivate enum ExerciseTypeLabelProvider {
    static func typeLabel(from ex: Exercise) -> String? {
        readableType(ex.type)
    }
    static func typeLabel(forDisplayName name: String) -> String? {
        // Heuristic fallback using the progression catalog equip heuristics
        let lower = name.lowercased()
        if lower.contains("barbell") || lower.contains("squat") || lower.contains("deadlift") || lower.contains("bench") || lower.contains("row") || lower.contains("press") { return "Barbell" }
        if lower.contains("dumbbell") || lower.contains(" db ") { return "Dumbbell" }
        if lower.contains("cable") || lower.contains("pulldown") { return "Cable" }
        if lower.contains("smith") { return "Smith" }
        if lower.contains("assist") { return "Assistance" }
        if lower.contains("bodyweight") { return "Bodyweight" }
        return nil
    }
    private static func readableType(_ t: Exercise.ExerciseType) -> String {
        switch t {
        case .machine: return "Machine"
        case .barbell: return "Barbell"
        case .smithMachine: return "Smith"
        case .dumbbell: return "Dumbbell"
        case .cable: return "Cable"
        case .bodyweightOnly: return "Bodyweight"
        case .bodyweightLoadable: return "Bodyweight+Load"
        case .machineAssistance: return "Assistance"
        }
    }
}

