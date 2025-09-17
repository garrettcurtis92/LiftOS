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
    @AppStorage("restTimerEnabled") private var restTimerEnabled: Bool = true

    // Session state
    @State private var session: WorkoutSession
    @FocusState private var focusedField: SessionField?

    // UI state
    @State private var showRestTimer = false
    @State private var lastRestDuration: Int = 90
    @State private var completed: [UUID: [ExerciseSet]] = [:] // exercise.id -> sets
    @State private var lastSummary: SessionSummary?
    @State private var sessionStart: Date? = nil
    //

    // Helper to show a full weekday name from currentDayIx (0-based)
    private func weekdayName(for ix: Int) -> String {
        // Start Monday as index 0
        let names = ["Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"]
        guard ix >= 0 && ix < names.count else { return "Day \(ix + 1)" }
        return names[ix]
    }

    init(dayLabel: String? = nil, preset: String) {
        self.dayLabel = dayLabel
        self.preset = preset
        self._session = State(initialValue: WorkoutSessionView.makeSession(title: preset))
    }

    var body: some View {
    List {
            // Train header to match other views
            VStack(alignment: .leading, spacing: 4) {
                Text("Train")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, DS.Space.lg.rawValue)
            .padding(.top, DS.Space.lg.rawValue)
            .listRowInsets(.init())
            .listRowBackground(Color.clear)
            
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
        .scrollContentBackground(.hidden)
        .background(WorkoutBackground())
        .listStyle(.insetGrouped)
    .navigationBarTitleDisplayMode(.inline)
        // Bottom finish bar (only when all sets done)
        .safeAreaInset(edge: .bottom) {
            if allSetsDone && !showRestTimer {
                HStack {
                    Spacer()
                    VStack(spacing: 0) {
                        PrimaryButton(title: "Finish Session", systemIcon: "checkmark.circle.fill", style: .success) {
                            Haptics.success()
                            finishSession()
                        }
                        .padding(.horizontal, DS.Space.lg.rawValue)
                        .padding(.vertical, DS.Space.md.rawValue)
                    }
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .shadow(radius: 8, y: 2)
                    .padding(.horizontal, DS.Space.lg.rawValue)
                    .padding(.bottom, DS.Space.xl.rawValue)
                    Spacer()
                }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.snappy, value: allSetsDone)
            }
        }
    .padding(.bottom, (allSetsDone && !showRestTimer) ? DS.Space.lg.rawValue : 0)
        // Apply week-based RIR on appear
        .onAppear {
            let target = MesocycleRules.rirTarget(forWeek: currentWeek)
            for i in session.exercises.indices { session.exercises[i].rirTarget = target }
        }
        .toolbar {
            // Two-line centered title with full weekday
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text(mesocycleName)
                        .font(.headline)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    Text("Week \(currentWeek) day \(currentDayIx + 1) \(weekdayName(for: currentDayIx))")
                        .font(TypeScale.subheadline())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .frame(maxWidth: .infinity)
            }
            // Keyboard accessory Done button
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focusedField = nil }
            }
        }
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    .sheet(item: $lastSummary, onDismiss: { advanceToNextDay() }) { s in
            NavigationStack { SessionSummaryView(summary: s) }
        }
        . sheet(isPresented: $showRestTimer) {
            RestTimerView(seconds: lastRestDuration) {
                showRestTimer = false
            }
        }
        
        .onChange(of: restTimerEnabled) { enabled in
            if !enabled { showRestTimer = false }
        }
        // Floating timer toggle button (bottom-right), stays out of the main flow
        .overlay(alignment: .bottomTrailing) {
            VStack {
                Button {
                    restTimerEnabled.toggle()
                    Haptics.tap()
                    if !restTimerEnabled { showRestTimer = false }
                } label: {
                    Image(systemName: restTimerEnabled ? "timer" : "timer.slash")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                        .padding(12)
                        .background(
                            Circle().fill(.regularMaterial)
                        )
                        .overlay(
                            Circle().strokeBorder(Color.primary.opacity(restTimerEnabled ? 0.12 : 0.28), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.18), radius: 6, y: 2)
                }
                .accessibilityLabel(restTimerEnabled ? "Disable rest timer" : "Enable rest timer")
                .padding(.trailing, DS.Space.lg.rawValue)
                .padding(.bottom, allSetsDone ? DS.Space.xxl.rawValue : DS.Space.lg.rawValue)
            }
        }
    }

    // MARK: - Derived
    private var mesocycleName: String {
        // If we add naming later, pull from ActiveMesocycleStore; for now use a friendly placeholder.
        return "Active Mesocycle"
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
        Haptics.success()
    }

    private func advanceToNextDay() {
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
        if checked && restTimerEnabled {
            showRestTimer = true
            lastRestDuration = 90
        }
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

struct WorkoutBackground: View {
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        LinearGradient(
            colors: scheme == .dark
                ? [Color.black, Color(white: 0.08)]
                : [Color(white: 0.98), Color(white: 0.94)],
            startPoint: .top, endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}
