import SwiftUI

struct SetListView: View {
    let exercise: ExerciseItem
    let existingSets: [ExerciseSet]
    let weightUnit: WeightUnit
    let lastReps: [Int: Int]
    let hasBaseline: Bool

    var onAddSet: () -> Void
    var onSkipSet: (_ index: Int) -> Void
    var onDeleteSet: (_ index: Int) -> Void
    var onCommitInline: (_ index: Int, _ weight: Double?, _ reps: Int?, _ checked: Bool) -> Void

    var focusedField: FocusState<SessionField?>.Binding

    private func existingSet(for index: Int) -> ExerciseSet? {
        existingSets.first(where: { $0.index == index })
    }

    private func row(for idx: Int) -> some View {
        let existing = existingSet(for: idx)
        let previousWeight: Double? = existingSets
            .filter { $0.index < idx }
            .compactMap { $0.weight }
            .last
        let suggestedWeight: Double? = hasBaseline ? exercise.suggestedNextWeight : nil

        return InlineSetRow(
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
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button { onSkipSet(idx) } label: {
                Label("Skip", systemImage: "forward.end")
            }
            Button(role: .destructive) { onDeleteSet(idx) } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .accessibilityHint("Swipe for skip or delete")
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
                HStack(spacing: 6) {
                    Text(exercise.name)
                    if let t = exercise.typeLabel, !t.isEmpty {
                        Text("(") + Text(t).foregroundStyle(.secondary) + Text(")")
                    }
                }
                .font(.headline)

                HStack(spacing: 8) {
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

private struct SetListView_PreviewContainer: View {
    @FocusState private var focusedField: SessionField?

    var body: some View {
        List {
            SetListView(
                exercise: ExerciseItem(name: "Bench Press", targetSets: 3, rirTarget: 2),
                existingSets: [],
                weightUnit: .lb,
                lastReps: [:],
                hasBaseline: false,
                onAddSet: {},
                onSkipSet: { _ in },
                onDeleteSet: { _ in },
                onCommitInline: { _,_,_,_ in },
                focusedField: $focusedField
            )
        }
    }
}

#Preview {
    SetListView_PreviewContainer()
}

