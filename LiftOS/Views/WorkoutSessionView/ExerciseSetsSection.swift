import SwiftUI

struct ExerciseSetsSection: View {
    let exercise: ExerciseItem
    let existingSets: [ExerciseSet]
    let weightUnit: WeightUnit

    let onAddSet: () -> Void
    let onSkipSet: (_ index: Int) -> Void
    let onDeleteSet: (_ index: Int) -> Void
    let onCommitInline: (_ index: Int, _ weight: Double?, _ reps: Int?, _ checked: Bool) -> Void

    var focusedField: FocusState<SessionField?>.Binding

    private func existingSet(for index: Int) -> ExerciseSet? {
        existingSets.first(where: { $0.index == index })
    }

    @ViewBuilder
    private func row(for idx: Int) -> some View {
        let existing = existingSet(for: idx)
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
            previousWeight: previousWeight,
            focusedField: focusedField,
            onCommit: { w, r, checked in onCommitInline(idx, w, r, checked) },
            onAddSet: onAddSet,
            onSkip: { onSkipSet(idx) },
            onDelete: { onDeleteSet(idx) }
        )
        .id("\(exercise.id)-\(idx)-\(existingSets.count)")
    }

    var body: some View {
        let doneCount: Int = Set(existingSets.map { $0.index }).count
        let indices: [Int] = Array(1...exercise.targetSets)

        return Section {
            ForEach(indices, id: \.self) { idx in
                row(for: idx)
            }
        } header: {
            VStack(alignment: .leading, spacing: 4) {
                ExerciseSectionHeader(primary: exercise.name, secondary: nil)
                HStack {
                    Spacer()
                    Text("\(doneCount)/\(exercise.targetSets)")
                        .font(TypeScale.footnote())
                        .foregroundStyle(DS.colors.secondaryLabel)
                        .monospaced()
                        .accessibilityLabel("Completed \(doneCount) of \(exercise.targetSets) sets")
                }
            }
        }
        .listRowBackground(Color.clear)
    }
}
