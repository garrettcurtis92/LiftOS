import SwiftUI

struct InlineSetRow: View {
    let exerciseID: UUID
    let index: Int
    let totalSets: Int
    let weightUnit: WeightUnit
    let rirTarget: Int
    let existing: ExerciseSet?
    let previousWeight: Double?
    let suggestedWeight: Double?
    let lastReps: Int?

    var focusedField: FocusState<SessionField?>.Binding

    var onCommit: (_ weight: Double?, _ reps: Int?, _ checked: Bool) -> Void
    var onAddSet: () -> Void
    var onSkip: () -> Void
    var onDelete: () -> Void

    @State private var weightText: String = ""
    @State private var repsText: String = ""
    @State private var checked: Bool = false
    @State private var wasWeightFocused: Bool = false
    @State private var missingFlashWeight: Bool = false
    @State private var missingFlashReps: Bool = false
    @State private var isProvisional: Bool = false
    @State private var suppressProvisionalFlip: Bool = false
    @State private var userHasEdited: Bool = false

    @AppStorage("provisionalWeightDim") private var provisionalWeightDim: Bool = true
    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true

    private enum RowState { case pending, active, done }
    private var isFocused: Bool {
        let f = focusedField.wrappedValue
        return f == .weight(exerciseID, index) || f == .reps(exerciseID, index)
    }
    private var rowState: RowState { checked ? .done : (isFocused ? .active : .pending) }
    private var pipColor: Color {
        switch rowState {
        case .pending: return .secondary.opacity(0.5)
        case .active: return MulticolorAccent.color(for: .primary)
        case .done: return .green
        }
    }

    init(
        exerciseID: UUID,
        index: Int,
        totalSets: Int,
        weightUnit: WeightUnit,
        rirTarget: Int,
        existing: ExerciseSet?,
        previousWeight: Double?,
        suggestedWeight: Double?,
        lastReps: Int?,
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
        self.suggestedWeight = suggestedWeight
        self.lastReps = lastReps
        self.focusedField = focusedField
        self.onCommit = onCommit
        self.onAddSet = onAddSet
        self.onSkip = onSkip
        self.onDelete = onDelete

        let initialWeight = existing?.weight.map { Self.formatWeightText($0) } ??
                            (suggestedWeight.map { Self.formatWeightText($0) } ?? "")
        _weightText = State(initialValue: initialWeight)
        _repsText   = State(initialValue: existing?.reps.map(String.init) ?? "")
        _checked    = State(initialValue: existing?.done ?? false)
        _isProvisional = State(initialValue: existing?.weight == nil && suggestedWeight != nil)
    }

    private var nudgeStep: Double {
        switch weightUnit {
        case .lb: return 2.5
        case .kg: return 2.5
        }
    }

    private static func formatWeightText(_ w: Double) -> String {
        let roundedTo1 = (w * 10).rounded() / 10
        if roundedTo1 == floor(roundedTo1) {
            return String(Int(roundedTo1))
        } else {
            return String(format: "%.1f", roundedTo1)
        }
    }

    private var repsPlaceholder: String {
        if let r = lastReps { return String(r) }
        return "\(rirTarget) RIR"
    }

    var body: some View {
        HStack(spacing: DS.Space.sm.rawValue) {
            // Leading progress pip
            Circle()
                .fill(pipColor)
                .frame(width: 10, height: 10)
                .scaleEffect(rowState == .active ? 1.15 : 1.0)
                .animation(UIAccessibility.isReduceMotionEnabled ? .linear(duration: 0.01) : .snappy(duration: 0.2), value: rowState)

            HStack(spacing: 8) {
                TextField(weightUnit.display, text: $weightText)
                    .keyboardType(.decimalPad)
                    .font(.body.monospacedDigit())
                    .numericTextTransitionIfAvailable()
                    .foregroundStyle(isProvisional && provisionalWeightDim ? .secondary : .primary)
                    .multilineTextAlignment(.leading)
                    .focused(focusedField, equals: .weight(exerciseID, index))
                    .submitLabel(.next)
                    .frame(minWidth: 44, minHeight: 44)
                    .padding(.leading, 12)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.red.opacity(missingFlashWeight ? 0.9 : 0), lineWidth: 1))
                    .accessibilityLabel("Set \(index), weight entry")
                    .accessibilityHint("Enter weight then reps. Double tap to mark set completed.")

                Button { nudgeWeight(-nudgeStep) } label: { Image(systemName: "minus.circle") }
                    .buttonStyle(.plain)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
                    .accessibilityLabel("Decrease weight")
                Button { nudgeWeight(+nudgeStep) } label: { Image(systemName: "plus.circle") }
                    .buttonStyle(.plain)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
                    .accessibilityLabel("Increase weight")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                focusedField.wrappedValue = .weight(exerciseID, index)
            }

            TextField(repsPlaceholder, text: $repsText)
                .keyboardType(.numberPad)
                .font(.body.monospacedDigit())
                .numericTextTransitionIfAvailable()
                .multilineTextAlignment(.center)
                .focused(focusedField, equals: .reps(exerciseID, index))
                .submitLabel(index < totalSets ? .next : .done)
                .frame(maxWidth: .infinity, minHeight: 44)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.red.opacity(missingFlashReps ? 0.9 : 0), lineWidth: 1))
                .accessibilityLabel("Repetitions")
                .accessibilityHint("Target \(rirTarget) R I R")
                .contentShape(Rectangle())
                .onTapGesture {
                    focusedField.wrappedValue = .reps(exerciseID, index)
                }

            Button {
                if weightText.isEmpty || repsText.isEmpty {
                    indicateMissingFields()
                    checked = false
                } else {
                    checked.toggle()
                    if checked {
                        if hapticsEnabled { Haptics.success() }
                        commit()
                    } else {
                        commitSoft()
                    }
                }
            } label: {
                Image(systemName: checked ? "checkmark.circle.fill" : "circle")
                    .imageScale(.large)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(checked ? Color.green : .secondary)
                    .frame(minWidth: 44, minHeight: 44)
                    .background(.thinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .if(!UIAccessibility.isReduceMotionEnabled) { view in
                view.symbolEffect(.bounce, value: checked)
            }
            .accessibilityLabel(checked ? "Set complete" : "Mark set complete")
            .accessibilityHint((weightText.isEmpty || repsText.isEmpty) ? "Enter weight and reps to complete" : "Double tap to toggle")
            .contentShape(Rectangle())
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            if checked {
                Button {
                    checked = false
                    commitSoft()
                } label: {
                    Label("Undo", systemImage: "arrow.uturn.left")
                }
            } else {
                Button {
                    if weightText.isEmpty || repsText.isEmpty {
                        indicateMissingFields()
                    } else {
                        checked = true
                        if hapticsEnabled { Haptics.success() }
                        commit()
                    }
                } label: {
                    Label("Mark Done", systemImage: "checkmark.circle.fill")
                }
                .tint(.green)
            }
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .onTapGesture {
            if focusedField.wrappedValue == nil {
                if weightText.isEmpty {
                    focusedField.wrappedValue = .weight(exerciseID, index)
                } else {
                    focusedField.wrappedValue = .reps(exerciseID, index)
                }
            }
        }
        .onSubmit {
            let current = focusedField.wrappedValue
            let next = nextField(after: current)
            focusedField.wrappedValue = next
            if case .reps(exerciseID, _) = current {
                if !weightText.isEmpty, !repsText.isEmpty {
                    checked = true
                    if hapticsEnabled { Haptics.success() }
                    commit()
                }
            }
        }
        .onChange(of: suggestedWeight) { oldValue, newValue in
            if PrefillPolicy.shouldPrefill(weightIsEmpty: weightText.isEmpty, userHasEdited: userHasEdited),
               let hint = newValue {
                isProvisional = true
                suppressProvisionalFlip = true
                weightText = Self.formatWeightText(hint)
                commitSoft()
            }
        }
        .onChange(of: weightText) {
            if suppressProvisionalFlip {
                suppressProvisionalFlip = false
                return
            }
            userHasEdited = true
            if !weightText.isEmpty {
                isProvisional = false
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
        .onChange(of: checked) { oldValue, newValue in
            #if canImport(UIKit)
            if newValue {
                UIAccessibility.post(notification: .announcement, argument: "Set \(index) completed")
            } else {
                UIAccessibility.post(notification: .announcement, argument: "Set \(index) unmarked")
            }
            #endif
        }
        .onAppear {
            if PrefillPolicy.shouldPrefill(weightIsEmpty: weightText.isEmpty, userHasEdited: userHasEdited),
               let hint = suggestedWeight {
                isProvisional = true
                suppressProvisionalFlip = true
                weightText = Self.formatWeightText(hint)
                commitSoft()
            }
        }
    }

    private func nudgeWeight(_ delta: Double) {
        let current = Double(weightText) ?? 0
        let newVal = max(0, current + delta)
        weightText = newVal == floor(newVal) ? String(Int(newVal)) : String(format: "%.1f", newVal)
        userHasEdited = true
        isProvisional = false
        focusedField.wrappedValue = .weight(exerciseID, index)
        commitSoft()
    }

    private func nextField(after current: SessionField?) -> SessionField? {
        switch current {
        case .weight(let id, let i) where id == exerciseID:
            return .reps(exerciseID, i)
        case .reps(let id, let i) where id == exerciseID:
            return i < totalSets ? .weight(exerciseID, i + 1) : nil
        default:
            return nil
        }
    }

    private func indicateMissingFields() {
        #if canImport(UIKit)
        if hapticsEnabled {
            let gen = UINotificationFeedbackGenerator()
            gen.notificationOccurred(.warning)
        }
        #endif
        if weightText.isEmpty {
            withAnimation(.easeIn(duration: 0.12)) { missingFlashWeight = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.easeOut(duration: 0.2)) { missingFlashWeight = false }
            }
        }
        if repsText.isEmpty {
            withAnimation(.easeIn(duration: 0.12)) { missingFlashReps = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.easeOut(duration: 0.2)) { missingFlashReps = false }
            }
        }
    }

    private func commitSoft() {
        onCommit(Double(weightText), Int(repsText), checked)
    }
    private func commit() {
        onCommit(Double(weightText), Int(repsText), checked)
    }
}

extension InlineSetRow: Equatable {
    static func == (lhs: InlineSetRow, rhs: InlineSetRow) -> Bool {
        lhs.exerciseID == rhs.exerciseID &&
        lhs.index == rhs.index &&
        lhs.totalSets == rhs.totalSets &&
        lhs.weightUnit == rhs.weightUnit &&
        lhs.rirTarget == rhs.rirTarget &&
        lhs.lastReps == rhs.lastReps &&
        lhs.suggestedWeight == rhs.suggestedWeight &&
        lhs.previousWeight == rhs.previousWeight &&
        lhs.existing?.weight == rhs.existing?.weight &&
        lhs.existing?.reps == rhs.existing?.reps &&
        lhs.existing?.done == rhs.existing?.done
    }
}

extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition { transform(self) } else { self }
    }
}
