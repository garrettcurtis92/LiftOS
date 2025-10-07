//
//  MesoScratchBuilderView.swift
//  LiftOS
//
//  Created by Garrett Curtis on 9/19/25.
//
import SwiftUI
import SwiftData

struct MesoScratchBuilderView: View {
    let name: String
    let weekCount: Int
    let daysPerWeek: Int
    let onComplete: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var selectedDayIx: Int = 0
    @State private var days: [[MuscleGroup]]
    @State private var showPicker = false
    @State private var activeGroupForExercises: MuscleGroup? = nil
    @State private var activeGroupIndex: Int? = nil
    @State private var exercisesByDay: [Int: [Int: [Exercise]]] = [:]

    // All days must have at least one selected exercise
    private var allDaysHaveAtLeastOneExercise: Bool {
        guard daysPerWeek > 0 else { return false }
        for dayIx in 0..<daysPerWeek {
            guard let map = exercisesByDay[dayIx], map.values.contains(where: { !$0.isEmpty }) else {
                return false
            }
        }
        return true
    }

    init(name: String, weeks: Int, daysPerWeek: Int, onComplete: (() -> Void)? = nil) {
        self.name = name
        self.weekCount = weeks
        self.daysPerWeek = daysPerWeek
        self.onComplete = onComplete
        // one empty array per day
        _days = State(initialValue: Array(repeating: [], count: max(1, daysPerWeek)))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Day selector — segmented, very Apple
            Picker("Day", selection: $selectedDayIx) {
                ForEach(0..<daysPerWeek, id: \.self) { ix in
                    Text("Day \(ix + 1)").tag(ix)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top)

            // Content for selected day
            if days[selectedDayIx].isEmpty {
                ContentUnavailableView(
                    "No exercises yet",
                    systemImage: "square.and.pencil",
                    description: Text("Tap the + to add a muscle group.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.clear)
            } else {
                List {
                    Section {
                        ForEach(Array(days[selectedDayIx].enumerated()), id: \.offset) { (idx, group) in
                            Button {
                                activeGroupForExercises = group
                                activeGroupIndex = idx
                            } label: {
                                HStack(alignment: .firstTextBaseline) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Label(group.title, systemImage: group.symbol)
                                            .font(.body)
                                        if let name = exercisesByDay[selectedDayIx]?[idx]?.first?.name {
                                            Text(name)
                                                .font(.footnote)
                                                .foregroundStyle(.secondary)
                                                .lineLimit(1)
                                        }
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.footnote)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        .onDelete { indexSet in
                            // Remove the groups from the day list
                            days[selectedDayIx].remove(atOffsets: indexSet)
                            // Reindex the exercises mapping for this day
                            if let map = exercisesByDay[selectedDayIx] {
                                var updated: [Int: [Exercise]] = [:]
                                for (oldIndex, exList) in map {
                                    // Skip removed indices
                                    if indexSet.contains(oldIndex) { continue }
                                    // Shift indices down by the number of removed items before this index
                                    let shift = indexSet.filter { $0 < oldIndex }.count
                                    let newIndex = oldIndex - shift
                                    updated[newIndex] = exList
                                }
                                exercisesByDay[selectedDayIx] = updated
                            }
                        }
                    } header: {
                        Text("Muscle groups")
                            .font(.headline)
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .background(DS.groupBg)
            }
        }
        .navigationTitle("New meso plan")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showPicker = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add muscle group")
            }
        }
        .safeAreaInset(edge: .bottom) {
            HStack {
                Button {
                    saveMesocycle()
                    // Dismiss builder first, then dismiss parent creator view
                    dismiss()
                    DispatchQueue.main.async {
                        if let onComplete { onComplete() }
                    }
                } label: {
                    Text("Create Mesocycle")
                        .font(.headline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .disabled(!allDaysHaveAtLeastOneExercise)
                .tint(.blue)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .sheet(isPresented: $showPicker) {
            MuscleGroupPicker { selected in
                days[selectedDayIx].append(selected)
            }
            .presentationDetents([.medium])
        }
        .sheet(item: $activeGroupForExercises) { group in
            ExercisePickerView(group: group) { exercise in
                var dayMap = exercisesByDay[selectedDayIx] ?? [:]
                if let ix = activeGroupIndex {
                    dayMap[ix] = [exercise]
                }
                exercisesByDay[selectedDayIx] = dayMap
            }
            .presentationDetents([.medium, .large])
        }
    }

    private func saveMesocycle() {
        // Basic validation: require at least one exercise per day
        guard allDaysHaveAtLeastOneExercise else { return }

        // Build immutable plan snapshot from the current UI selections
        var snapshot: [MesoDayTemplate] = []
        for dayIx in 0..<daysPerWeek {
            let map = exercisesByDay[dayIx] ?? [:]
            let ordered = map.keys.sorted()
            var templates: [MesoExerciseTemplate] = []
            for key in ordered {
                guard let ex = map[key]?.first else { continue }
                let display = ex.name
                let norm = PlanKey.normalize(display)
                // Default sets and rep window. Today we don’t collect per-ex values in the builder, so use 3 x 8...10.
                let defaultSets = 3
                let repLo: Int? = 8
                let repHi: Int? = 10
                let notes: String? = nil
                templates.append(MesoExerciseTemplate(
                    exerciseDisplayName: display,
                    normalizedKey: norm,
                    defaultSets: defaultSets,
                    repRangeLower: repLo,
                    repRangeUpper: repHi,
                    notes: notes
                ))
            }
            snapshot.append(MesoDayTemplate(dayIx: dayIx, exercises: templates))
        }

        let finalName = name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "New Mesocycle" : name.trimmingCharacters(in: .whitespacesAndNewlines)
        let meso = Mesocycle(
            name: finalName,
            weekCount: weekCount,
            daysPerWeek: daysPerWeek,
            status: .current,
            startDate: Date(),
            labelStyle: .fixedWeekdays
        )
        meso.planSnapshot = snapshot

        // Also persist relational structure for existing UIs; sessions will prefer snapshot when available.
        for dayIx in 0..<daysPerWeek {
            let day = MesoDay(index: dayIx)
            day.mesocycle = meso
            let map = exercisesByDay[dayIx] ?? [:]
            for (idx, exList) in map.sorted(by: { $0.key < $1.key }) {
                // Use the original selected muscle group from days array (by index)
                let group = days[dayIx][idx]
                let selection = MesoSelection(muscleGroupRaw: group.rawValue, exercise: exList.first)
                selection.day = day
                day.selections.append(selection)
            }
            meso.days.append(day)
        }

        modelContext.insert(meso)
        MesocycleStore.setCurrent(meso, in: modelContext)
        try? modelContext.save()
    }
}

// MARK: - Muscle Group Picker (simple, native)
private struct MuscleGroupPicker: View {
    var onSelect: (MuscleGroup) -> Void
    @Environment(\.dismiss) private var dismiss

    private let groups: [MuscleGroup] = [
        .chest, .back, .shoulders, .biceps, .triceps,
        .quads, .hamstrings, .glutes, .calves, .core
    ]

    var body: some View {
        NavigationStack {
            List(groups, id: \.self) { g in
                Button {
                    onSelect(g)
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: g.symbol)
                        Text(g.title)
                        Spacer()
                    }
                }
            }
            .navigationTitle("Add muscle group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Types
enum MuscleGroup: String, Hashable, CaseIterable, Identifiable {
    case chest, back, shoulders, biceps, triceps
    case quads, hamstrings, glutes, calves, core

    var title: String {
        switch self {
        case .chest: "Chest"
        case .back: "Back"
        case .shoulders: "Shoulders"
        case .biceps: "Biceps"
        case .triceps: "Triceps"
        case .quads: "Quads"
        case .hamstrings: "Hamstrings"
        case .glutes: "Glutes"
        case .calves: "Calves"
        case .core: "Core"
        }
    }

    var symbol: String {
        switch self {
        case .chest: "figure.strengthtraining.traditional"
        case .back: "figure.rower"
        case .shoulders: "figure.strengthtraining.functional"
        case .biceps: "arm.flex"
        case .triceps: "bolt.circle"
        case .quads: "figure.run"
        case .hamstrings: "figure.walk"
        case .glutes: "figure.step.training"
        case .calves: "hare"
        case .core: "seal"
        }
    }
}

extension MuscleGroup {
    var id: String { rawValue }
}

private extension MuscleGroup {
    var exerciseGroup: Exercise.MuscleGroup {
        switch self {
        case .chest: return .chest
        case .back: return .back
        case .shoulders: return .shoulders
        case .biceps: return .biceps
        case .triceps: return .triceps
        case .quads: return .quads
        case .hamstrings: return .hamstrings
        case .glutes: return .glutes
        case .calves: return .calves
        case .core: return .abs
        }
    }
}

private struct ExercisePickerView: View {
    let group: MuscleGroup
    var onAdd: (Exercise) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var exercises: [Exercise] = []
    @State private var query: String = ""
    @State private var isLoading: Bool = true

    var body: some View {
        NavigationStack {
            if isLoading {
                ProgressView("Loading…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if exercises.isEmpty {
                ContentUnavailableView {
                    Label("No exercises for \(group.title)", systemImage: "line.3.horizontal.decrease.circle")
                } description: {
                    Text("No exercises found in catalog.")
                }
            } else {
                let filtered = exercises.filter { query.isEmpty || $0.name.localizedCaseInsensitiveContains(query) }
                List {
                    ForEach(Array(filtered.enumerated()), id: \.offset) { (i, ex) in
                        Button {
                            onAdd(ex)
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "dumbbell")
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(ex.name)
                                }
                                Spacer()
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Add \(group.title)")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search exercises")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
        }
        .task(id: group) {
            isLoading = true
            let store = ExerciseStore(modelContext: modelContext)
            let all = store.prefills + store.customs
            let target = group.exerciseGroup
            exercises = all
                .filter { $0.muscleGroup == target }
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            isLoading = false
        }
    }
}

#Preview {
    MesoScratchBuilderView(name: "Example", weeks: 4, daysPerWeek: 4)
}

