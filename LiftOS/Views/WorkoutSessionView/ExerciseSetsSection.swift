import SwiftUI

struct ExerciseSetsSection: View {
    let exercise: ExerciseItem
    let existingSets: [ExerciseSet]
    let weightUnit: WeightUnit
    let lastReps: [Int: Int]

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
        let suggestedWeight: Double? = exercise.suggestedNextWeight

        InlineSetRow(
            exerciseID: exercise.id,
            index: idx,
            totalSets: exercise.targetSets,
            weightUnit: weightUnit,
            rirTarget: exercise.rirTarget,
            existing: existing,
            previousWeight: previousWeight,
            suggestedWeight: suggestedWeight,
            lastReps: lastReps[idx],
            focusedField: focusedField,
            onCommit: { w, r, checked in onCommitInline(idx, w, r, checked) },
            onAddSet: onAddSet,
            onSkip: { onSkipSet(idx) },
            onDelete: { onDeleteSet(idx) }
        )
        .id("\(exercise.id)-\(idx)-\(existingSets.count)")
    }

    var body: some View {
        let doneCount: Int = Set(existingSets.filter { $0.done }.map { $0.index }).count
        let indices: [Int] = Array(1...exercise.targetSets)

        return Section {
            ForEach(indices, id: \.self) { idx in
                row(for: idx)
            }
            Button {
                onAddSet()
            } label: {
                HStack {
                    Spacer()
                    Label("Add set", systemImage: "plus")
                        .labelStyle(.titleAndIcon)
                        .font(.callout.weight(.semibold))
                    Spacer()
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Add set")
        } header: {
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.headline)

                // Visible hint: prefer logged data when available, otherwise show next suggestion
                HStack(spacing: 8) {
                    // Find the highest indexed logged set to represent the "last" set
                    let lastLogged = existingSets.max(by: { $0.index < $1.index })
                    if let lw = lastLogged?.weight, (lastLogged?.reps != nil || lw > 0) {
                        if let reps = lastLogged?.reps {
                            Text("Logged: \(formatWeight(lw)) × \(reps)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Logged: \(formatWeight(lw))")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    } else if let suggested = exercise.suggestedNextWeight {
                        Text("Next: \(formatWeight(suggested))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                ProgressView(value: Double(doneCount), total: Double(exercise.targetSets))
                    .progressViewStyle(.linear)
                    .tint(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(exercise.name) progress")
            .accessibilityValue("\(doneCount) of \(exercise.targetSets) sets")
        }
        .listRowBackground(Color.clear)
    }

    private func formatWeight(_ x: Double) -> String {
        let unit = weightUnit
        let rounded = (x.rounded() == x) ? "\(Int(x))" : String(format: "%.1f", x)
        return unit == .kg ? "\(rounded) kg" : "\(rounded) lb"
    }
}
