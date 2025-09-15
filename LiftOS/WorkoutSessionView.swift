//
//  WorkoutSessionView.swift
//  LiftOS
//

import SwiftUI

// MARK: - Helpers (local types)

private struct PresentedExerciseSet: Identifiable {
    var id: UUID { exerciseSet.id }
    let exercise: ExerciseItem
    var exerciseSet: ExerciseSet
}

// MARK: - WorkoutSessionView

struct WorkoutSessionView: View {
    // Inputs
    var dayLabel: String? = nil

    // Session (built from a simple preset in init)
    @State private var session: WorkoutSession

    // UI State
    @State private var showRestTimer = false
    @State private var lastRestDuration: Int = 90  // seconds, default for inline flow
    @State private var completed: [UUID: [ExerciseSet]] = [:] // exercise.id -> sets
    @State private var showSummary = false
    @State private var lastSummary: SessionSummary?
    @State private var sessionStart: Date? = nil

    // App storage / prefs
    @AppStorage("currentWeek")    private var currentWeek: Int = 1
    @AppStorage("currentDayIx")   private var currentDayIx: Int = 0
    @AppStorage("daysPerWeek")    private var daysPerWeek: Int = 3
    @AppStorage("weightUnit")     private var weightUnit: WeightUnit = .lb

    // Progress
    private var plannedSetCount: Int {
        session.exercises.reduce(0) { $0 + $1.targetSets }
    }
    private var completedUniqueCount: Int {
        session.exercises.reduce(0) { acc, ex in
            let arr = completed[ex.id] ?? []
            let unique = Set(arr.map { $0.index })
            return acc + unique.count
        }
    }
    private var allSetsDone: Bool {
        plannedSetCount > 0 && completedUniqueCount >= plannedSetCount
    }

    // Init builds demo session from preset (Push/Pull/Legs/Accessory)
    init(dayLabel: String? = nil, preset: String? = nil) {
        self.dayLabel = dayLabel

        let (title, exercises): (String, [ExerciseItem])
        switch preset {
        case "Pull":
            (title, exercises) = (
                "Pull Day",
                [
                    ExerciseItem(name: "Lat Pulldown",        targetSets: 3, rirTarget: 3),
                    ExerciseItem(name: "Seated Row",          targetSets: 3, rirTarget: 3),
                    ExerciseItem(name: "Face Pull",           targetSets: 3, rirTarget: 3),
                    ExerciseItem(name: "Hammer Curl",         targetSets: 3, rirTarget: 3)
                ]
            )
        case "Legs":
            (title, exercises) = (
                "Legs Day",
                [
                    ExerciseItem(name: "Back Squat",          targetSets: 3, rirTarget: 3),
                    ExerciseItem(name: "Romanian Deadlift",   targetSets: 3, rirTarget: 3),
                    ExerciseItem(name: "Leg Press",           targetSets: 3, rirTarget: 3),
                    ExerciseItem(name: "Calf Raise",          targetSets: 3, rirTarget: 3)
                ]
            )
        case "Push":
            fallthrough
        default:
            (title, exercises) = (
                "Push Day",
                [
                    ExerciseItem(name: "Incline DB Press",    targetSets: 3, rirTarget: 3),
                    ExerciseItem(name: "Cable Fly",           targetSets: 3, rirTarget: 3),
                    ExerciseItem(name: "Lateral Raise",       targetSets: 3, rirTarget: 3),
                    ExerciseItem(name: "Triceps Pressdown",   targetSets: 3, rirTarget: 3)
                ]
            )
        }

        _session = State(initialValue: WorkoutSession(title: title, exercises: exercises))
    }

    // MARK: - Body

    var body: some View {
        List {
            Section {
                Text("RIR Target: \(session.exercises.first?.rirTarget ?? 3)")
                    .font(TypeScale.subheadline())
                    .foregroundStyle(DS.colors.secondaryLabel)
            }

            ForEach(session.exercises) { exercise in
                ExerciseSetsSection(
                    exercise: exercise,
                    existingSets: completed[exercise.id] ?? [],
                    weightUnit: weightUnit,
                    onAddSet: {
                        if let i = session.exercises.firstIndex(where: { $0.id == exercise.id }) {
                            session.exercises[i].targetSets += 1
                        }
                    },
                    onSkipSet: { idx in
                        let exID = exercise.id
                        var arr = completed[exID, default: []]
                        if arr.firstIndex(where: { $0.index == idx }) == nil {
                            arr.append(ExerciseSet(index: idx, weight: nil, reps: nil, rir: nil, done: true))
                        }
                        completed[exID] = arr
                    },
                    onDeleteSet: { idx in
                        let exID = exercise.id
                        if var arr = completed[exID] {
                            arr.removeAll { $0.index == idx }
                            completed[exID] = arr
                        }
                        if let i = session.exercises.firstIndex(where: { $0.id == exercise.id }) {
                            if idx == session.exercises[i].targetSets, session.exercises[i].targetSets > 1 {
                                session.exercises[i].targetSets -= 1
                            }
                        }
                    },
                    onCommitInline: { idx, weight, reps, checked in
                        if sessionStart == nil { sessionStart = Date() }
                        let exID = exercise.id
                        var arr = completed[exID, default: []]
                        let newSet = ExerciseSet(index: idx, weight: weight, reps: reps, rir: nil, done: checked)
                        if let pos = arr.firstIndex(where: { $0.index == idx }) {
                            arr[pos] = newSet
                        } else {
                            arr.append(newSet)
                        }
                        completed[exID] = arr

                        // Start rest timer when checked
                        if checked {
                            showRestTimer = true
                            lastRestDuration = 90
                        }
                    }
                )
            }
        }
        .navigationTitle(dayLabel.map { "\(session.title) — \($0)" } ?? session.title)

        // Rest timer
        .fullScreenCover(isPresented: $showRestTimer) {
            RestTimerView(
                seconds: lastRestDuration,
                onDone: {
                    Haptics.success()
                    showRestTimer = false
                }
            )
        }

        // Summary
        .sheet(isPresented: $showSummary) {
            NavigationStack {
                if let s = lastSummary {
                    SessionSummaryView(summary: s)
                }
            }
        }

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
            for i in session.exercises.indices {
                session.exercises[i].rirTarget = target
            }
        }
    }

    // MARK: - Actions

    private func finishSession() {
        let setsFlat = session.exercises.flatMap { ex in
            (completed[ex.id] ?? []).map { CompletedSet(from: $0, exerciseName: ex.name) }
        }
        var summary = SessionSummary(title: session.title, date: Date(), sets: setsFlat)

        if let start = sessionStart {
            summary.durationSeconds = max(1, Int(Date().timeIntervalSince(start)))
        }

        SummaryStore.shared.load()
        SummaryStore.shared.save(summary)
        lastSummary = summary
        showSummary = true

        // Auto-advance Day (wrap)
        let next = currentDayIx + 1
        currentDayIx = next >= daysPerWeek ? 0 : next
    }
}

// MARK: - ExerciseSetsSection (inline editing)

private struct ExerciseSetsSection: View {
    let exercise: ExerciseItem
    let existingSets: [ExerciseSet]
    let weightUnit: WeightUnit

    // callbacks
    let onAddSet: () -> Void
    let onSkipSet: (_ index: Int) -> Void
    let onDeleteSet: (_ index: Int) -> Void
    let onCommitInline: (_ index: Int, _ weight: Double?, _ reps: Int?, _ checked: Bool) -> Void

    private func existingSet(for index: Int) -> ExerciseSet? {
        existingSets.first(where: { $0.index == index })
    }

    var body: some View {
        let doneCount: Int = Set(existingSets.map { $0.index }).count
        let indices: [Int] = Array(1...exercise.targetSets)

        return Section {
            ForEach(indices, id: \.self) { idx in
                let existing = existingSet(for: idx)
                InlineSetRow(
                    index: idx,
                    weightUnit: weightUnit,
                    rirTarget: exercise.rirTarget,
                    existing: existing,
                    onCommit: { w, r, checked in
                        onCommitInline(idx, w, r, checked)
                    },
                    onAddSet: onAddSet,
                    onSkip: { onSkipSet(idx) },
                    onDelete: { onDeleteSet(idx) }
                )
            }
        } header: {
            HStack {
                Text(exercise.name)
                Spacer()
                Text("\(doneCount)/\(exercise.targetSets)")
                    .font(TypeScale.footnote())
                    .foregroundStyle(DS.colors.secondaryLabel)
                    .monospaced()
                    .accessibilityLabel("Completed \(doneCount) of \(exercise.targetSets) sets")
            }
        }
    }
}

// MARK: - InlineSetRow – weight (left), reps (middle), checkbox (right) + menu

private struct InlineSetRow: View {
    let index: Int
    let weightUnit: WeightUnit
    let rirTarget: Int
    let existing: ExerciseSet?

    var onCommit: (_ weight: Double?, _ reps: Int?, _ checked: Bool) -> Void
    var onAddSet: () -> Void
    var onSkip: () -> Void
    var onDelete: () -> Void

    @State private var weightText: String = ""
    @State private var repsText: String = ""
    @State private var checked: Bool = false

    init(index: Int,
         weightUnit: WeightUnit,
         rirTarget: Int,
         existing: ExerciseSet?,
         onCommit: @escaping (_ weight: Double?, _ reps: Int?, _ checked: Bool) -> Void,
         onAddSet: @escaping () -> Void,
         onSkip: @escaping () -> Void,
         onDelete: @escaping () -> Void) {

        self.index = index
        self.weightUnit = weightUnit
        self.rirTarget = rirTarget
        self.existing = existing
        self.onCommit = onCommit
        self.onAddSet = onAddSet
        self.onSkip = onSkip
        self.onDelete = onDelete

        _weightText = State(initialValue: existing?.weight.map { String(Int($0)) } ?? "")
        _repsText   = State(initialValue: existing?.reps.map(String.init) ?? "")
        _checked    = State(initialValue: existing?.done ?? false)
    }

    var body: some View {
        HStack(spacing: DS.Space.sm.rawValue) {
            // LEFT: Weight + menu (ellipsis first)
            HStack(spacing: 8) {
                Menu {
                    Button("Add set", action: onAddSet)
                    Button("Skip set", action: onSkip)
                    Button(role: .destructive) { onDelete() } label: { Text("Delete set") }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .imageScale(.medium)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Set options")
                }

                TextField(weightUnit.display, text: $weightText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // MIDDLE: Reps
            TextField("\(rirTarget) RIR", text: $repsText)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            // RIGHT: Checkbox
            Button {
                checked.toggle()
                commit()
            } label: {
                Image(systemName: checked ? "checkmark.square.fill" : "square")
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onSubmit { commit() }
        .onChange(of: weightText) { _ in commitSoft() }
        .onChange(of: repsText)   { _ in commitSoft() }
    }

    // MARK: - Helpers used by .onSubmit/.onChange/checkbox
    private func commitSoft() {
        onCommit(Double(weightText), Int(repsText), checked)
    }
    private func commit() {
        onCommit(Double(weightText), Int(repsText), checked)
    }
}
