import SwiftUI

struct ExercisePage: View {
    let exercise: ExerciseItem
    let exerciseIndex: Int
    let totalExercises: Int
    let completed: [UUID: [ExerciseSet]]
    let weightUnit: WeightUnit
    let lastReps: [Int: Int]
    let hasBaseline: Bool
    
    var onAddSet: () -> Void
    var onSkipSet: (_ index: Int) -> Void
    var onDeleteSet: (_ index: Int) -> Void
    var onCommitInline: (_ index: Int, _ weight: Double?, _ reps: Int?, _ checked: Bool) -> Void
    
    @FocusState var focusedField: SessionField?
    
    private var existingSets: [ExerciseSet] {
        completed[exercise.id] ?? []
    }
    
    private func existingSet(for index: Int) -> ExerciseSet? {
        existingSets.first(where: { $0.index == index })
    }
    
    private func previousWeight(for index: Int) -> Double? {
        existingSets
            .filter { $0.index < index }
            .compactMap { $0.weight }
            .last
    }
    
    private var exerciseTypeKey: String {
        exercise.name.lowercased()
    }
    
    var body: some View {
        // Remove ScrollView wrapper since we're inside a List
        // The List itself handles scrolling
        VStack(spacing: FitnessDS.Space.interExercise) {  // Semantic token: spacing within exercise
            // Sets section
            VStack(spacing: FitnessDS.Space.interSet) {  // Semantic token: between set rows
                ForEach(1...exercise.targetSets, id: \.self) { index in
                    InlineSetRow(
                        exerciseID: exercise.id,
                        index: index,
                        totalSets: exercise.targetSets,
                        weightUnit: weightUnit,
                        rirTarget: exercise.rirTarget,
                        existing: existingSet(for: index),
                        previousWeight: previousWeight(for: index),
                        suggestedWeight: hasBaseline ? exercise.suggestedNextWeight : nil,
                        lastReps: lastReps[index],
                        focusedField: $focusedField,
                        onCommit: { w, r, checked in onCommitInline(index, w, r, checked) },
                        onAddSet: onAddSet,
                        onSkip: { onSkipSet(index) },
                        onDelete: { onDeleteSet(index) }
                    )
                    .id("\(exercise.id)-\(index)")  // Stable ID combining exercise and set index
                    .padding(.horizontal, FitnessDS.Space.lg.rawValue)
                }

                // Add set button
                Button {
                    Haptics.tap()
                    onAddSet()
                } label: {
                    Label("Add Set", systemImage: "plus")
                        .font(.body)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                .padding(.top, FitnessDS.Space.interControls)  // Semantic token: spacing to controls
                .padding(.bottom, 4)
            }
            .padding(.top, 0)  // No top padding for tighter sections
            
            // Bottom spacing for safe area
            Spacer(minLength: 40)  // Minimal bottom spacer for very tight layout
        }
    }
    
    // MARK: - Helper Functions
    
    private func iconForExerciseType(_ type: String) -> String {
        let lowerType = type.lowercased()
        if lowerType.contains("barbell") {
            return "rectangle.and.hand.point.up.left.filled"
        } else if lowerType.contains("dumbbell") {
            return "dumbbell.fill"
        } else if lowerType.contains("machine") {
            return "gear"
        } else if lowerType.contains("cable") {
            return "cable.connector"
        } else if lowerType.contains("bodyweight") {
            return "figure.strengthtraining.traditional"
        } else {
            return "dumbbell"
        }
    }
}

// MARK: - Preview

#Preview("Exercise Page") {
    let sampleExercise = ExerciseItem(
        name: "Barbell Bench Press",
        targetSets: 3,
        rirTarget: 2,
        typeLabel: "Barbell"
    )
    
    ExercisePage(
        exercise: sampleExercise,
        exerciseIndex: 0,
        totalExercises: 4,
        completed: [:],
        weightUnit: .lb,
        lastReps: [1: 8, 2: 8, 3: 8],
        hasBaseline: true,
        onAddSet: { },
        onSkipSet: { _ in },
        onDeleteSet: { _ in },
        onCommitInline: { _, _, _, _ in }
    )
}