//
//  WorkoutSessionView.swift
//  LiftOS
//

import SwiftUI

struct WorkoutSessionView: View {
    // Input
    var dayLabel: String? = nil
    private let preset: String

    // App-wide prefs used within view
    @AppStorage("weightUnit") private var weightUnit: WeightUnit = .lb
    @AppStorage("daysPerWeek") private var daysPerWeek: Int = 3
    @AppStorage("currentWeek") private var currentWeek: Int = 1
    @AppStorage("currentDayIx") private var currentDayIx: Int = 0

    // Session state
    @State private var session: WorkoutSession
    @FocusState private var focusedField: SessionField?

    // UI state
    @State private var showRestTimer = false
    @State private var lastRestDuration: Int = 90
    @State private var completed: [UUID: [ExerciseSet]] = [:] // exercise.id -> sets
    @State private var lastSummary: SessionSummary?
    @State private var sessionStart: Date? = nil

    init(dayLabel: String? = nil, preset: String) {
        self.dayLabel = dayLabel
        self.preset = preset
        self._session = State(initialValue: WorkoutSessionView.makeSession(title: preset))
    }

    var body: some View {
        List {
            ForEach(session.exercises) { ex in
                ExerciseSetsSection(
                    exercise: ex,
                    existingSets: completed[ex.id] ?? [],
                    weightUnit: weightUnit,
                    onAddSet: { handleAddSet(for: ex) },
                    onSkipSet: { idx in handleSkipSet(for: ex, index: idx) },
                    onDeleteSet: { idx in handleDeleteSet(for: ex, index: idx) },
                    onCommitInline: { idx, w, r, checked in handleCommitInline(for: ex, index: idx, weight: w, reps: r, checked: checked) },
                    focusedField: $focusedField
                )
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        // Bottom finish bar (only when all sets done)
        .safeAreaInset(edge: .bottom) {
            if allSetsDone {
                VStack(spacing: 0) {
                    Divider()
                    PrimaryButton(title: "Finish Session", systemIcon: "checkmark.circle.fill") {
                        Haptics.success()
                        finishSession()
                    }
                    .padding(.horizontal, DS.Space.lg.rawValue)
                    .padding(.vertical, DS.Space.md.rawValue)
                }
                .background(.bar)
            }
        }
        .padding(.bottom, allSetsDone ? DS.Space.xl.rawValue : 0)
        // Apply week-based RIR on appear
        .onAppear {
            let target = MesocycleRules.rirTarget(forWeek: currentWeek)
            for i in session.exercises.indices { session.exercises[i].rirTarget = target }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focusedField = nil }
            }
        }
        .sheet(item: $lastSummary, onDismiss: { advanceToNextDay() }) { s in
            NavigationStack { SessionSummaryView(summary: s) }
        }
        .sheet(isPresented: $showRestTimer) {
            RestTimerView(seconds: lastRestDuration) {
                showRestTimer = false
            }
        }
    }

    // MARK: - Derived
    private var navigationTitle: String {
        if let d = dayLabel { return "\(preset) · \(d)" }
        return preset
    }
    private var allSetsDone: Bool {
        // All exercises have their target set indices present in completed map
        for ex in session.exercises {
            let doneIndices = Set((completed[ex.id] ?? []).map { $0.index })
            if doneIndices.count < ex.targetSets { return false }
        }
        return true
    }

    // MARK: - Actions
    private func finishSession() {
        let setsFlat = session.exercises.flatMap { ex in
            (completed[ex.id] ?? []).map { CompletedSet(from: $0, exerciseName: ex.name) }
        }
        let built = SummaryBuilder.build(title: session.title, date: Date(), sets: setsFlat, sessionStart: sessionStart)
        lastSummary = built.summary
    }

    private func advanceToNextDay() {
        if let summary = lastSummary {
            SummaryStore.shared.load()
            SummaryStore.shared.save(summary)
        }
        let next = currentDayIx + 1
        if next >= daysPerWeek { currentWeek += 1; currentDayIx = 0 } else { currentDayIx = next }
        completed = [:]
        lastSummary = nil
        sessionStart = nil
        // Re-seed a new session for the same preset (next day)
        session = WorkoutSessionView.makeSession(title: preset)
        let target = MesocycleRules.rirTarget(forWeek: currentWeek)
        for i in session.exercises.indices { session.exercises[i].rirTarget = target }
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
    }
    private func handleDeleteSet(for exercise: ExerciseItem, index: Int) {
        let exID = exercise.id
        if var arr = completed[exID] { arr.removeAll { $0.index == index }; completed[exID] = arr }
        if let i = session.exercises.firstIndex(where: { $0.id == exercise.id }) {
            if index == session.exercises[i].targetSets, session.exercises[i].targetSets > 1 {
                session.exercises[i].targetSets -= 1
            }
        }
    }
    private func handleCommitInline(for exercise: ExerciseItem, index: Int, weight: Double?, reps: Int?, checked: Bool) {
        if sessionStart == nil { sessionStart = Date() }
        let exID = exercise.id
        var arr = completed[exID, default: []]
        let newSet = ExerciseSet(index: index, weight: weight, reps: reps, rir: nil, done: checked)
        if let pos = arr.firstIndex(where: { $0.index == index }) { arr[pos] = newSet } else { arr.append(newSet) }
        completed[exID] = arr
        if checked { showRestTimer = true; lastRestDuration = 90 }
    }

    // MARK: - Session factory
    private static func makeSession(title: String) -> WorkoutSession {
        let ex: [ExerciseItem]
        switch title.lowercased() {
        case "push": ex = [ ExerciseItem(name: "Bench Press", targetSets: 4, rirTarget: 3), ExerciseItem(name: "Overhead Press", targetSets: 3, rirTarget: 3), ExerciseItem(name: "Incline DB Press", targetSets: 3, rirTarget: 3) ]
        case "pull": ex = [ ExerciseItem(name: "Deadlift", targetSets: 3, rirTarget: 3), ExerciseItem(name: "Barbell Row", targetSets: 4, rirTarget: 3), ExerciseItem(name: "Lat Pulldown", targetSets: 3, rirTarget: 3) ]
        case "legs": ex = [ ExerciseItem(name: "Back Squat", targetSets: 4, rirTarget: 3), ExerciseItem(name: "Leg Press", targetSets: 3, rirTarget: 3), ExerciseItem(name: "Leg Curl", targetSets: 3, rirTarget: 3) ]
        default: ex = [ ExerciseItem(name: "DB Curl", targetSets: 3, rirTarget: 3), ExerciseItem(name: "Triceps Pushdown", targetSets: 3, rirTarget: 3) ]
        }
        return WorkoutSession(title: title, exercises: ex)
    }
}
