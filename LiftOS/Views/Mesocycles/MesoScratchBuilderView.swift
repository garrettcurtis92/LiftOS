//
//  MesoScratchBuilderView.swift
//  LiftOS
//
//  Created by Garrett Curtis on 9/19/25.
//
import SwiftUI

struct MesoScratchBuilderView: View {
    let daysPerWeek: Int

    @Environment(\.dismiss) private var dismiss
    @State private var selectedDayIx: Int = 0
    @State private var days: [[MuscleGroup]]
    @State private var showPicker = false
    @State private var showExercisePicker = false
    @State private var activeGroupForExercises: MuscleGroup? = nil
    @State private var exercisesByDay: [Int: [MuscleGroup: [Exercise]]] = [:]

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

    init(daysPerWeek: Int) {
        self.daysPerWeek = daysPerWeek
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
                    Section("Muscle groups") {
                        ForEach(days[selectedDayIx], id: \.self) { group in
                            Button {
                                activeGroupForExercises = group
                                showExercisePicker = true
                            } label: {
                                HStack(alignment: .firstTextBaseline) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Label(group.title, systemImage: group.symbol)
                                        if let name = exercisesByDay[selectedDayIx]?[group]?.first?.name {
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
                            days[selectedDayIx].remove(atOffsets: indexSet)
                        }
                    }
                }
                .listStyle(.insetGrouped)
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
                    // TODO: build + save model, then dismiss()
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
        .sheet(isPresented: $showExercisePicker) {
            if let group = activeGroupForExercises {
                ExercisePickerView(group: group) { exercise in
                    var dayMap = exercisesByDay[selectedDayIx] ?? [:]
                    dayMap[group] = [exercise]
                    exercisesByDay[selectedDayIx] = dayMap
                }
                .presentationDetents([.medium, .large])
            }
        }
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
enum MuscleGroup: String, Hashable, CaseIterable {
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

    var body: some View {
        NavigationStack {
            if exercises.isEmpty {
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
        .task {
            // Load catalog from your store (prefills + customs), then filter by schema muscleGroup
            let store = ExerciseStore(modelContext: modelContext)
            let all = store.prefills + store.customs
            let target = group.exerciseGroup
            exercises = all
                .filter { $0.muscleGroup == target }
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }
    }
}

#Preview {
    MesoScratchBuilderView(daysPerWeek: 4)
}

