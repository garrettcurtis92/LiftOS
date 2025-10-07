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
    
    // Sensory feedback triggers
    @State private var setCompleteTrigger = 0
    @State private var fieldFocusTrigger = 0
    @State private var missingFieldsTrigger = 0

    @AppStorage("provisionalWeightDim") private var provisionalWeightDim: Bool = true
    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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

        // Priority: existing logged weight > previous set weight > suggested weight from prior sessions
        let initialWeight = existing?.weight.map { Self.formatWeightText($0) } ??
                            (previousWeight.map { Self.formatWeightText($0) } ??
                            (suggestedWeight.map { Self.formatWeightText($0) } ?? ""))
        _weightText = State(initialValue: initialWeight)
        _repsText   = State(initialValue: existing?.reps.map(String.init) ?? "")
        _checked    = State(initialValue: existing?.done ?? false)
        _isProvisional = State(initialValue: existing?.weight == nil && (previousWeight != nil || suggestedWeight != nil))
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
    
    private let corner: CGFloat = 12
    
    private var rowContent: some View {
        DSCard {
            HStack(spacing: FitnessDS.Space.md.rawValue) {
                // Set number indicator
                Text("\(index)")
                    .font(.subheadline.weight(.semibold))
                    .frame(width: 28, height: 28)
                    .background(.thickMaterial, in: Circle())
                    .overlay(Circle().stroke(DS.sep))
                
                weightInputSection
                repsInputField
                Spacer()
                completionToggle
            }
            .frame(maxHeight: 52)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(accessibilityRowLabel))
        .accessibilityHint(Text("Edit weight and reps, then mark complete."))
    }

    var body: some View {
        rowContent
            .sensoryFeedback(.success, trigger: setCompleteTrigger)
            .sensoryFeedback(.selection, trigger: fieldFocusTrigger)
            .sensoryFeedback(.warning, trigger: missingFieldsTrigger)
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
                        setCompleteTrigger += 1
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
            .onChange(of: previousWeight) { oldValue, newValue in
                // When a previous set in the same session is logged, prefill this set
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
            .onChange(of: focusedField.wrappedValue) { oldValue, newValue in
                let weightField = SessionField.weight(exerciseID, index)
                let repsField = SessionField.reps(exerciseID, index)

                let isWeightFocused = newValue == weightField
                let wasWeightFocusedPreviously = oldValue == weightField

                if wasWeightFocusedPreviously && !isWeightFocused && !weightText.isEmpty {
                    commit()
                }

                let rowJustBecameFocused = (newValue == weightField || newValue == repsField) && oldValue != newValue
                if rowJustBecameFocused {
                    fieldFocusTrigger += 1
                }
            }
            .contextMenu {
                Button {
                    print("🗑️ Delete from context menu for set \(index)")
                    onDelete()
                } label: {
                    Label("Delete Set", systemImage: "trash")
                }
                
                Button {
                    print("⏭️ Skip from context menu for set \(index)")
                    onSkip()
                } label: {
                    Label("Skip Set", systemImage: "minus.circle")
                }
            }
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
            if checked {
                Button {
                    checked = false
                    commitSoft()
                } label: {
                    Label("Undo", systemImage: "arrow.uturn.left")
                }
                .tint(FitnessDS.FitnessTint.warning)
            } else {
                Button {
                    if weightText.isEmpty || repsText.isEmpty {
                        indicateMissingFields()
                    } else {
                        checked = true
                        setCompleteTrigger += 1
                        commit()
                    }
                } label: {
                    Label("Mark Done", systemImage: "checkmark.circle.fill")
                }
                .tint(FitnessDS.FitnessTint.success)
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button {
                print("🗑️ Delete button tapped for set \(index)")
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
            .tint(.red)
            
            Button {
                print("⏭️ Skip button tapped for set \(index)")
                onSkip()
            } label: {
                Label("Skip", systemImage: "minus.circle")
            }
            .tint(.orange)
        }
    }

    private var setIndicator: some View {
        Text("\(index)")
            .font(FitnessDS.Typography.captionLarge)
            .fontWeight(.semibold)
            .foregroundStyle(pipColor)
            .frame(width: 24, height: 24)
            .background(
                Circle()
                    .fill(pipColor.opacity(0.15))
                    .allowsHitTesting(false)  // Decorative only
                    .overlay(
                        Circle()
                            .stroke(pipColor.opacity(0.3), lineWidth: 1)
                            .allowsHitTesting(false)  // Decorative only
                    )
            )
            .scaleEffect(reduceMotion ? 1.0 : (rowState == .active ? 1.08 : 1.0))
            .opacity(reduceMotion && rowState == .active ? 0.9 : 1.0)
            .animation(reduceMotion ? .easeInOut(duration: 0.25) : .snappy(duration: 0.35, extraBounce: 0.25), value: rowState)
            .accessibilityHidden(true)
    }

    private var weightInputSection: some View {
        HStack(spacing: FitnessDS.Space.xs.rawValue) {
            weightTextField
            weightNudgeControls
        }
        .onTapGesture {
            focusedField.wrappedValue = .weight(exerciseID, index)
        }
    }

    private var weightTextField: some View {
        TextField(weightUnit.display, text: $weightText)
            .keyboardType(.decimalPad)
            .font(FitnessDS.Typography.numericMedium)
            .monospacedDigit()
            .numericTextTransitionIfAvailable()
            .foregroundStyle(weightTextForegroundStyle)
            .multilineTextAlignment(.center)
            .focused(focusedField, equals: .weight(exerciseID, index))
            .submitLabel(.next)
            .frame(minWidth: 60, minHeight: 48)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: FitnessDS.Corners.small))
            .overlay(
                RoundedRectangle(cornerRadius: FitnessDS.Corners.small)
                    .stroke(
                        fieldBorderColor(isMissing: missingFlashWeight),
                        lineWidth: fieldBorderWidth(isMissing: missingFlashWeight)
                    )
                    .allowsHitTesting(false)  // Decorative stroke only
            )
            .accessibilityLabel("Weight")
            .accessibilityValue(weightText.isEmpty ? "Empty" : "\(weightText) \(weightUnit.display)")
            .accessibilityHint("Enter weight for set \(index)")
    }

    private var weightNudgeControls: some View {
        VStack(spacing: 2) {
            Button { nudgeWeight(+nudgeStep) } label: {
                Image(systemName: "plus")
                    .font(.caption2)
                    .fontWeight(.semibold)
            }
            .buttonStyle(.plain)
            .frame(width: 28, height: 20)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 4))
            .foregroundStyle(.secondary)
            .accessibilityLabel("Increase weight")

            Button { nudgeWeight(-nudgeStep) } label: {
                Image(systemName: "minus")
                    .font(.caption2)
                    .fontWeight(.semibold)
            }
            .buttonStyle(.plain)
            .frame(width: 28, height: 20)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 4))
            .foregroundStyle(.secondary)
            .accessibilityLabel("Decrease weight")
        }
    }

    private var repsInputField: some View {
        TextField(repsPlaceholder, text: $repsText)
            .keyboardType(.numberPad)
            .font(FitnessDS.Typography.numericMedium)
            .monospacedDigit()
            .numericTextTransitionIfAvailable()
            .multilineTextAlignment(.center)
            .focused(focusedField, equals: .reps(exerciseID, index))
            .submitLabel(index < totalSets ? .next : .return)
            .frame(minWidth: 60, minHeight: 48)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: FitnessDS.Corners.small))
            .overlay(
                RoundedRectangle(cornerRadius: FitnessDS.Corners.small)
                    .stroke(
                        fieldBorderColor(isMissing: missingFlashReps),
                        lineWidth: fieldBorderWidth(isMissing: missingFlashReps)
                    )
                    .allowsHitTesting(false)  // Decorative stroke only
            )
            .accessibilityLabel("Repetitions")
            .accessibilityValue(repsText.isEmpty ? "Empty" : "\(repsText) reps")
            .accessibilityHint("Target \(rirTarget) RIR for set \(index)")
            .onTapGesture {
                focusedField.wrappedValue = .reps(exerciseID, index)
            }
    }

    private var completionToggle: some View {
        Button {
            if weightText.isEmpty || repsText.isEmpty {
                indicateMissingFields()
                checked = false
            } else {
                checked.toggle()
                if checked {
                    setCompleteTrigger += 1
                    commit()
                } else {
                    commitSoft()
                }
            }
        } label: {
            Image(systemName: checked ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(checked ? FitnessDS.FitnessTint.success : .secondary)
                .frame(width: 48, height: 48)
                .background(.thinMaterial, in: Circle())
                .overlay(
                    Circle()
                        .stroke(
                            checked ? FitnessDS.FitnessTint.success.opacity(0.3) : Color(.separator).opacity(0.2),
                            lineWidth: 1
                        )
                        .allowsHitTesting(false)  // Decorative stroke only
                )
        }
        .buttonStyle(.plain)
        .if(!reduceMotion) { view in
            view.symbolEffect(.bounce, value: checked)
        }
        .accessibilityLabel(checked ? "Set complete" : "Mark set complete")
        .accessibilityHint((weightText.isEmpty || repsText.isEmpty) ? "Enter weight and reps to complete" : "Double tap to toggle")
    }

    private var weightTextForegroundStyle: Color {
        (isProvisional && provisionalWeightDim) ? .secondary : .primary
    }

    private func fieldBorderColor(isMissing: Bool) -> Color {
        if isMissing { return .red }
        if rowState == .active { return FitnessDS.FitnessTint.primary.opacity(0.5) }
        return Color(.separator).opacity(0.3)
    }

    private func fieldBorderWidth(isMissing: Bool) -> CGFloat {
        isMissing ? 2 : 1
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
        missingFieldsTrigger += 1
        if weightText.isEmpty {
            triggerMissingFlashWeight()
        }
        if repsText.isEmpty {
            triggerMissingFlashReps()
        }
    }

    private func commitSoft() {
        onCommit(Double(weightText), Int(repsText), checked)
    }
    private func commit() {
        onCommit(Double(weightText), Int(repsText), checked)
    }

    private func triggerMissingFlashWeight() {
        if reduceMotion {
            missingFlashWeight = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                missingFlashWeight = false
            }
        } else {
            withAnimation(.easeIn(duration: 0.12)) { missingFlashWeight = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.easeOut(duration: 0.2)) { missingFlashWeight = false }
            }
        }
    }

    private func triggerMissingFlashReps() {
        if reduceMotion {
            missingFlashReps = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                missingFlashReps = false
            }
        } else {
            withAnimation(.easeIn(duration: 0.12)) { missingFlashReps = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.easeOut(duration: 0.2)) { missingFlashReps = false }
            }
        }
    }

    private var accessibilityRowLabel: String {
        let weightPart: String
        if let enteredWeight = Double(weightText) {
            weightPart = "Weight \(Self.formatWeightText(enteredWeight)) \(weightUnitSpeechLabel)"
        } else if let existingWeight = existing?.weight {
            weightPart = "Weight \(Self.formatWeightText(existingWeight)) \(weightUnitSpeechLabel)"
        } else if let suggested = suggestedWeight {
            weightPart = "Weight suggested \(Self.formatWeightText(suggested)) \(weightUnitSpeechLabel)"
        } else {
            weightPart = "Weight not entered"
        }

        let repsPart: String
        if let enteredReps = Int(repsText) {
            repsPart = "Reps \(enteredReps)"
        } else if let existingReps = existing?.reps {
            repsPart = "Reps \(existingReps)"
        } else if let last = lastReps {
            repsPart = "Reps last time \(last)"
        } else {
            repsPart = "Reps not entered"
        }

        let status = checked ? "Completed" : "Pending"
        return "Set \(index). \(weightPart). \(repsPart). \(status)."
    }

    private var weightUnitSpeechLabel: String {
        switch weightUnit {
        case .lb: return "pounds"
        case .kg: return "kilograms"
        }
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
