import SwiftUI

struct InlineSetRow: View {
    let exerciseID: UUID
    let index: Int
    let totalSets: Int
    let weightUnit: WeightUnit
    let rirTarget: Int
    let existing: ExerciseSet?
    let previousWeight: Double?

    var focusedField: FocusState<SessionField?>.Binding

    var onCommit: (_ weight: Double?, _ reps: Int?, _ checked: Bool) -> Void
    var onAddSet: () -> Void
    var onSkip: () -> Void
    var onDelete: () -> Void

    @State private var weightText: String = ""
    @State private var repsText: String = ""
    @State private var checked: Bool = false
    @State private var wasWeightFocused: Bool = false

    init(
        exerciseID: UUID,
        index: Int,
        totalSets: Int,
        weightUnit: WeightUnit,
        rirTarget: Int,
        existing: ExerciseSet?,
        previousWeight: Double?,
        focusedField: FocusState<SessionField?>.Binding,
        onCommit: @escaping (_ weight: Double?, _ reps: Int?, _ checked: Bool) -> Void,
        onAddSet: @escaping () -> Void,
        onSkip: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.exerciseID = exerciseID
        self.index = index
        self.totalSets = totalSets
        self.weightUnit = weightUnit
        self.rirTarget = rirTarget
        self.existing = existing
        self.previousWeight = previousWeight
        self.focusedField = focusedField
        self.onCommit = onCommit
        self.onAddSet = onAddSet
        self.onSkip = onSkip
        self.onDelete = onDelete

        let initialWeight = existing?.weight.map { String(Int($0)) } ??
                           (previousWeight.map { String(Int($0)) } ?? "")
        _weightText = State(initialValue: initialWeight)
        _repsText   = State(initialValue: existing?.reps.map(String.init) ?? "")
        _checked    = State(initialValue: existing?.done ?? false)
    }

    private var nudgeStep: Double {
        switch weightUnit {
        case .lb: return 5.0
        case .kg: return 2.5
        }
    }

    var body: some View {
        HStack(spacing: DS.Space.sm.rawValue) {
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
                    .focused(focusedField, equals: .weight(exerciseID, index))
                    .submitLabel(.next)
                    .frame(minWidth: 44)

                Button { nudgeWeight(-nudgeStep) } label: { Image(systemName: "minus.circle") }
                    .buttonStyle(.plain)
                Button { nudgeWeight(+nudgeStep) } label: { Image(systemName: "plus.circle") }
                    .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            TextField("\(rirTarget) RIR", text: $repsText)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .focused(focusedField, equals: .reps(exerciseID, index))
                .submitLabel(index < totalSets ? .next : .done)
                .frame(maxWidth: .infinity)

            Button {
                if weightText.trimmingCharacters(in: .whitespaces).isEmpty &&
                   repsText.trimmingCharacters(in: .whitespaces).isEmpty {
                    checked = true
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
        .onChange(of: previousWeight) {
            if weightText.isEmpty, let newWeight = previousWeight {
                weightText = String(Int(newWeight))
            }
        }
        .onChange(of: focusedField.wrappedValue) {
            let thisWeightField = SessionField.weight(exerciseID, index)
            let isNowFocused = focusedField.wrappedValue == thisWeightField
            if wasWeightFocused && !isNowFocused && !weightText.isEmpty {
                commit()
            }
            wasWeightFocused = isNowFocused
        }
    }

    private func nudgeWeight(_ delta: Double) {
        let current = Double(weightText) ?? previousWeight ?? 0
        let newVal = max(0, current + delta)
        weightText = newVal == floor(newVal) ? String(Int(newVal)) : String(format: "%.1f", newVal)
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
