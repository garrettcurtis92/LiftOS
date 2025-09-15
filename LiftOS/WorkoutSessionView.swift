//
//  WorkoutSessionView.swift
//  LiftOS
//

import SwiftUI

fileprivate enum SessionField: Hashable {
    case weight(UUID, Int) // (exerciseID, setIndex)
    case reps(UUID, Int)
}

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
    @FocusState private var focusedField: SessionField?

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
                    onAddSet: { handleAddSet(for: exercise) },
                    onSkipSet: { idx in handleSkipSet(for: exercise, index: idx) },
                    onDeleteSet: { idx in handleDeleteSet(for: exercise, index: idx) },
                    onCommitInline: { idx, weight, reps, checked in
                        handleCommitInline(for: exercise, index: idx, weight: weight, reps: reps, checked: checked)
                    },
                    focusedField: $focusedField
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
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    // Commit current field if it has content
                    if let currentField = focusedField {
                        switch currentField {
                        case .weight(_, _):
                            // Trigger weight auto-fill by dismissing focus
                            break
                        case .reps(_, _):
                            // No special action needed for reps
                            break
                        }
                    }
                    focusedField = nil
                }
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
        if var arr = completed[exID] {
            arr.removeAll { $0.index == index }
            completed[exID] = arr
        }
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
        if let pos = arr.firstIndex(where: { $0.index == index }) {
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
    // Focus within THIS exercise (uses exercise.id + set index)
    var focusedField: FocusState<SessionField?>.Binding

    private func existingSet(for index: Int) -> ExerciseSet? {
        existingSets.first(where: { $0.index == index })
    }

    @ViewBuilder
    private func row(for idx: Int) -> some View {
        let existing = existingSet(for: idx)
        // last non-nil weight from prior sets of this exercise
        let previousWeight: Double? = existingSets
            .filter { $0.index < idx }
            .compactMap { $0.weight }
            .last

        InlineSetRow(
            exerciseID: exercise.id,
            index: idx,
            totalSets: exercise.targetSets,
            weightUnit: weightUnit,
            rirTarget: exercise.rirTarget,
            existing: existing,
            previousWeight: previousWeight,          // ⬅️ NEW
            focusedField: focusedField,
            onCommit: { w, r, checked in
                onCommitInline(idx, w, r, checked)
            },
            onAddSet: onAddSet,
            onSkip: { onSkipSet(idx) },
            onDelete: { onDeleteSet(idx) }
        )
        .id("\(exercise.id)-\(idx)-\(existingSets.count)") // Force refresh when existingSets changes
    }

    var body: some View {
        let doneCount: Int = Set(existingSets.map { $0.index }).count
        let indices: [Int] = Array(1...exercise.targetSets)

        return Section {
            ForEach(indices, id: \.self) { idx in
                row(for: idx)
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

// MARK: - InlineSetRow – weight (left), reps (middle), check (right) + menu + focus + defaults
private struct InlineSetRow: View {
    let exerciseID: UUID
    let index: Int
    let totalSets: Int
    let weightUnit: WeightUnit
    let rirTarget: Int
    let existing: ExerciseSet?
    let previousWeight: Double?                     // ⬅️ NEW

    // Focus from parent
    var focusedField: FocusState<SessionField?>.Binding

    // Callbacks
    var onCommit: (_ weight: Double?, _ reps: Int?, _ checked: Bool) -> Void
    var onAddSet: () -> Void
    var onSkip: () -> Void
    var onDelete: () -> Void

    // Local UI state
    @State private var weightText: String = ""
    @State private var repsText: String = ""
    @State private var checked: Bool = false
    @State private var wasWeightFocused: Bool = false

    init(exerciseID: UUID,
         index: Int,
         totalSets: Int,
         weightUnit: WeightUnit,
         rirTarget: Int,
         existing: ExerciseSet?,
         previousWeight: Double?,                                // ⬅️ NEW
         focusedField: FocusState<SessionField?>.Binding,
         onCommit: @escaping (_ weight: Double?, _ reps: Int?, _ checked: Bool) -> Void,
         onAddSet: @escaping () -> Void,
         onSkip: @escaping () -> Void,
         onDelete: @escaping () -> Void) {

        self.exerciseID = exerciseID
        self.index = index
        self.totalSets = totalSets
        self.weightUnit = weightUnit
        self.rirTarget = rirTarget
        self.existing = existing
        self.previousWeight = previousWeight                     // ⬅️ NEW
        self.focusedField = focusedField
        self.onCommit = onCommit
        self.onAddSet = onAddSet
        self.onSkip = onSkip
        self.onDelete = onDelete

        // Smart default: use previousWeight if no existing weight
        let initialWeight = existing?.weight.map { String(Int($0)) } ??
                           (previousWeight.map { String(Int($0)) } ?? "")
        
        _weightText = State(initialValue: initialWeight)
        _repsText   = State(initialValue: existing?.reps.map(String.init) ?? "")
        _checked    = State(initialValue: existing?.done ?? false)
    }

    // Nudge step based on unit (simple default for now)
    private var nudgeStep: Double {
        switch weightUnit {
        case .lb: return 5.0
        case .kg: return 2.5
        }
    }

    var body: some View {
        HStack(spacing: DS.Space.sm.rawValue) {

            // LEFT: menu + weight + nudges
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

                // Weight field
                TextField(weightUnit.display, text: $weightText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.leading)
                    .focused(focusedField, equals: .weight(exerciseID, index))
                    .submitLabel(.next)
                    .frame(minWidth: 44)

                // Nudge –
                Button {
                    nudgeWeight(-nudgeStep)
                } label: {
                    Image(systemName: "minus.circle")
                }
                .buttonStyle(.plain)

                // Nudge +
                Button {
                    nudgeWeight(+nudgeStep)
                } label: {
                    Image(systemName: "plus.circle")
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // MIDDLE: Reps
            TextField("\(rirTarget) RIR", text: $repsText)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .focused(focusedField, equals: .reps(exerciseID, index))
                .submitLabel(index < totalSets ? .next : .done)
                .frame(maxWidth: .infinity)

            // RIGHT: Check chip
            Button {
                // Guardrail: if both fields empty, treat as Skip (no numbers)
                if weightText.trimmingCharacters(in: .whitespaces).isEmpty &&
                   repsText.trimmingCharacters(in: .whitespaces).isEmpty {
                    checked = true
                    // Commit with nils (skip-style complete)
                    onCommit(nil, nil, true)
                } else {
                    checked.toggle()
                    commit()
                }
            } label: {
                Image(systemName: checked ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(checked ? Color.accentColor : Color.secondary)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onSubmit { handleSubmit() }
        .onChange(of: repsText) { commitSoft() }
        .onChange(of: previousWeight) { newPreviousWeight in
            // Update weight field if it's empty and we have a new previous weight
            if weightText.isEmpty, let newWeight = newPreviousWeight {
                weightText = String(Int(newWeight))
            }
        }
        .onChange(of: focusedField.wrappedValue) { newFocus in
            let thisWeightField = SessionField.weight(exerciseID, index)
            let isNowFocused = newFocus == thisWeightField
            
            // If this weight field just lost focus and has content, commit immediately
            if wasWeightFocused && !isNowFocused && !weightText.isEmpty {
                commit()
            }
            
            // Update tracking state
            wasWeightFocused = isNowFocused
        }
    }

    // MARK: - Flow helpers

    private func nudgeWeight(_ delta: Double) {
        let current = Double(weightText) ?? previousWeight ?? 0
        let newVal = max(0, current + delta)
        weightText = newVal == floor(newVal) ? String(Int(newVal)) : String(format: "%.1f", newVal)
        // stay on weight field when nudging
        focusedField.wrappedValue = .weight(exerciseID, index)
        commitSoft()
    }

    private func handleSubmit() {
        switch focusedField.wrappedValue {
        case .weight(exerciseID, index):
            focusedField.wrappedValue = .reps(exerciseID, index)
        case .reps(exerciseID, index):
            if index < totalSets {
                focusedField.wrappedValue = .weight(exerciseID, index + 1)
            } else {
                focusedField.wrappedValue = nil
            }
            // If both present, auto-check on submit
            if !weightText.isEmpty, !repsText.isEmpty {
                checked = true
                commit()
            }
        default:
            break
        }
    }

    private func commitSoft() {
        onCommit(Double(weightText), Int(repsText), checked)
    }
    private func commit() {
        onCommit(Double(weightText), Int(repsText), checked)
    }
}
