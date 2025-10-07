import SwiftUI

struct ExerciseListView: View {
    let exercises: [ExerciseItem]
    let completed: [UUID: [ExerciseSet]]
    let weightUnit: WeightUnit
    let lastRepsProvider: (ExerciseItem) -> [Int: Int]
    let hasBaseline: (ExerciseItem) -> Bool

    var onAddSet: (ExerciseItem) -> Void
    var onSkipSet: (ExerciseItem, Int) -> Void
    var onDeleteSet: (ExerciseItem, Int) -> Void
    var onCommitInline: (ExerciseItem, Int, Double?, Int?, Bool) -> Void

    @FocusState var focusedField: SessionField?

    var body: some View {
        List {
            ForEach(exercises) { ex in
                SetListView(
                    exercise: ex,
                    existingSets: completed[ex.id] ?? [],
                    weightUnit: weightUnit,
                    lastReps: lastRepsProvider(ex),
                    hasBaseline: hasBaseline(ex),
                    onAddSet: { onAddSet(ex) },
                    onSkipSet: { idx in onSkipSet(ex, idx) },
                    onDeleteSet: { idx in onDeleteSet(ex, idx) },
                    onCommitInline: { idx, w, r, checked in onCommitInline(ex, idx, w, r, checked) },
                    focusedField: $focusedField
                )
            }
        }
        .listStyle(.insetGrouped)
        .listSectionSpacing(20)  // Increased spacing between exercises
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedField = nil
                }
            }
        }
    }
}

#Preview {
    ExerciseListView(
        exercises: [ExerciseItem(name: "Bench Press", targetSets: 3, rirTarget: 2)],
        completed: [:],
        weightUnit: .lb,
        lastRepsProvider: { _ in [:] },
        hasBaseline: { _ in false },
        onAddSet: { _ in },
        onSkipSet: { _,_  in },
        onDeleteSet: { _,_ in },
        onCommitInline: { _,_,_,_,_ in }
    )
}
