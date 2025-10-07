import SwiftUI

struct ExercisePageView: View {
    let exercise: ExerciseItem
    let completed: [UUID: [ExerciseSet]]
    let weightUnit: WeightUnit
    let lastReps: [Int: Int]
    let hasBaseline: Bool
    let isActive: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var onAddSet: () -> Void
    var onSkipSet: (_ index: Int) -> Void
    var onDeleteSet: (_ index: Int) -> Void
    var onCommitInline: (_ index: Int, _ weight: Double?, _ reps: Int?, _ checked: Bool) -> Void
    
    @FocusState var focusedField: SessionField?
    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true
    
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
    
    private var accentColor: Color {
        FitnessDS.FitnessTint.forKey(exerciseTypeKey)
    }
    
    private var isDone: Bool {
        let completedSets = existingSets.filter { $0.done && $0.weight != nil && $0.reps != nil }
        return completedSets.count >= exercise.targetSets && exercise.targetSets > 0
    }
    
    private var muscleGroup: String {
        // Extract muscle group from exercise name or type
        let name = exercise.name.lowercased()
        if name.contains("bench") || name.contains("press") && name.contains("chest") {
            return "Chest"
        } else if name.contains("squat") || name.contains("leg") {
            return "Legs"
        } else if name.contains("row") || name.contains("pulldown") || name.contains("lat") {
            return "Back"
        } else if name.contains("curl") && !name.contains("leg") {
            return "Biceps"
        } else if name.contains("extension") || name.contains("pushdown") {
            return "Triceps"
        } else if name.contains("shoulder") || name.contains("lateral") {
            return "Shoulders"
        } else {
            return "Full Body"
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            headerSection
            setListSection
            Spacer(minLength: 80)
        }
        .background { backgroundTint }
        .toolbar { keyboardToolbar }
    }
}

// MARK: - Preview

private extension ExercisePageView {
    private var headerSection: some View {
        ExerciseHeaderSection(
            exerciseName: exercise.name,
            muscleGroup: muscleGroup,
            typeLabel: exercise.typeLabel,
            accentColor: accentColor,
            isActive: isActive,
            isDone: isDone
        )
        .padding(.horizontal, FitnessDS.Space.lg.rawValue)
        .padding(.top, FitnessDS.Space.xl.rawValue)
        .padding(.bottom, FitnessDS.Space.lg.rawValue)
    }

    private var setListSection: some View {
        ExerciseSetListSection(
            exercise: exercise,
            weightUnit: weightUnit,
            hasBaseline: hasBaseline,
            lastReps: lastReps,
            accentColor: accentColor,
            isDone: isDone,
            isActive: isActive,
            hapticsEnabled: hapticsEnabled,
            focusedField: $focusedField,
            existingSet: existingSet(for:),
            previousWeight: previousWeight(for:),
            onAddSet: onAddSet,
            onSkipSet: onSkipSet,
            onDeleteSet: onDeleteSet,
            onCommitInline: onCommitInline
        )
    }

    private var backgroundTint: some View {
        accentColor
            .opacity(isDone ? 0.05 : 0.02)
            .ignoresSafeArea()
            .animation(reduceMotion ? .easeInOut(duration: 0.4) : FitnessDS.Animations.slowEase, value: isDone)
    }

    @ToolbarContentBuilder
    private var keyboardToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .keyboard) {
            Spacer()
            Button("Done") { focusedField = nil }
                .foregroundStyle(FitnessDS.FitnessTint.primary)
        }
    }
}

private struct ExerciseHeaderSection: View {
    let exerciseName: String
    let muscleGroup: String
    let typeLabel: String?
    let accentColor: Color
    let isActive: Bool
    let isDone: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var successColor: Color { .green }

    var body: some View {
        VStack(spacing: FitnessDS.Space.md.rawValue) {
            titleBlock
            tagline
            completionBadge
        }
    }

    private var titleBlock: some View {
        VStack(spacing: FitnessDS.Space.xs.rawValue) {
            Text(exerciseName)
                .font(FitnessDS.Typography.displayMedium)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .scaleEffect(reduceMotion ? 1.0 : (isActive ? 1.02 : 1.0))
                .opacity(reduceMotion && isActive ? 0.92 : 1.0)
                .animation(reduceMotion ? .easeInOut(duration: 0.25) : .snappy(duration: 0.4, extraBounce: 0.2), value: isActive)
            if isActive {
                Rectangle()
                    .fill(accentColor)
                    .frame(height: 2)
                    .frame(maxWidth: 80)
                    .opacity(0.8)
                    .shadow(color: accentColor.opacity(reduceMotion ? 0.4 : 1.0), radius: reduceMotion ? 2 : 4)
            }
        }
    }

    private var tagline: some View {
        var text = Text(muscleGroup)
            .foregroundStyle(.primary)

        if let typeLabel {
            text = text + Text(" • ")
                .foregroundStyle(.tertiary)
            text = text + Text(typeLabel)
                .foregroundStyle(.secondary)
        }

        return text
            .font(FitnessDS.Typography.bodySmall)
            .fontWeight(.medium)
            .multilineTextAlignment(.center)
            .lineLimit(2)
    }

    @ViewBuilder
    private var completionBadge: some View {
        if isDone {
            HStack(spacing: FitnessDS.Space.xs.rawValue) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(successColor)
                Text("Complete")
                    .font(FitnessDS.Typography.captionLarge)
                    .fontWeight(.medium)
                    .foregroundStyle(successColor)
            }
            .padding(.horizontal, FitnessDS.Space.md.rawValue)
            .padding(.vertical, FitnessDS.Space.xs.rawValue)
            .background(successColor.opacity(0.15), in: Capsule())
            .overlay(
                Capsule()
                    .stroke(successColor.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

private struct ExerciseSetListSection: View {
    let exercise: ExerciseItem
    let weightUnit: WeightUnit
    let hasBaseline: Bool
    let lastReps: [Int: Int]
    let accentColor: Color
    let isDone: Bool
    let isActive: Bool
    let hapticsEnabled: Bool
    let focusedField: FocusState<SessionField?>.Binding
    let existingSet: (Int) -> ExerciseSet?
    let previousWeight: (Int) -> Double?
    let onAddSet: () -> Void
    let onSkipSet: (Int) -> Void
    let onDeleteSet: (Int) -> Void
    let onCommitInline: (Int, Double?, Int?, Bool) -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var setIndices: [Int] {
        guard exercise.targetSets > 0 else { return [] }
        return Array(1...exercise.targetSets)
    }

    var body: some View {
        VStack(spacing: FitnessDS.Space.md.rawValue) {
            ForEach(setIndices, id: \.self) { index in
                setRow(for: index)
                    .padding(.horizontal, FitnessDS.Space.lg.rawValue)
            }
            addSetButton
        }
        .padding(.horizontal, FitnessDS.Space.lg.rawValue)
        .padding(.vertical, FitnessDS.Space.xl.rawValue)
        .background(
            RoundedRectangle(cornerRadius: FitnessDS.Corners.card)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: FitnessDS.Corners.card)
                .stroke(
                    isDone ? Color.green.opacity(0.3) : Color(.separator).opacity(0.3),
                    lineWidth: 1
                )
        )
        .fitnessShadow(FitnessDS.Shadows.cardShadow)
        .padding(.horizontal, FitnessDS.Space.lg.rawValue)
    .scaleEffect(reduceMotion ? 1.0 : (isActive ? 1.005 : 1.0))
    .opacity(reduceMotion && isActive ? 0.95 : 1.0)
    .animation(reduceMotion ? .easeInOut(duration: 0.2) : .snappy(duration: 0.35, extraBounce: 0.25), value: isActive)
    }

    private func setRow(for index: Int) -> some View {
        InlineSetRow(
            exerciseID: exercise.id,
            index: index,
            totalSets: exercise.targetSets,
            weightUnit: weightUnit,
            rirTarget: exercise.rirTarget,
            existing: existingSet(index),
            previousWeight: previousWeight(index),
            suggestedWeight: hasBaseline ? exercise.suggestedNextWeight : nil,
            lastReps: lastReps[index],
            focusedField: focusedField,
            onCommit: { w, r, checked in
                onCommitInline(index, w, r, checked)
                if checked && hapticsEnabled {
                    Haptics.success()
                }
            },
            onAddSet: onAddSet,
            onSkip: { onSkipSet(index) },
            onDelete: { onDeleteSet(index) }
        )
    }

    private var addSetButton: some View {
        Button {
            if hapticsEnabled { Haptics.tap() }
            onAddSet()
        } label: {
            HStack(spacing: FitnessDS.Space.sm.rawValue) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                Text("Add Set")
                    .font(FitnessDS.Typography.bodyMedium)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(accentColor)
            .padding(.horizontal, FitnessDS.Space.xl.rawValue)
            .padding(.vertical, FitnessDS.Space.md.rawValue)
            .background(.thinMaterial, in: Capsule())
            .overlay(
                Capsule()
                    .stroke(accentColor.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .padding(.top, FitnessDS.Space.md.rawValue)
    }
}

#Preview("Exercise Page View") {
    let sampleExercise = ExerciseItem(
        name: "Barbell Bench Press",
        targetSets: 3,
        rirTarget: 2,
        typeLabel: "Barbell"
    )
    
    ScrollView {
        ExercisePageView(
            exercise: sampleExercise,
            completed: [:],
            weightUnit: .lb,
            lastReps: [1: 8, 2: 8, 3: 8],
            hasBaseline: true,
            isActive: true,
            onAddSet: { },
            onSkipSet: { _ in },
            onDeleteSet: { _ in },
            onCommitInline: { _, _, _, _ in }
        )
    }
    .background(Color.black)
}

#Preview("Exercise Page View - Complete") {
    let sampleExercise = ExerciseItem(
        name: "Dumbbell Rows",
        targetSets: 3,
        rirTarget: 1,
        typeLabel: "Dumbbell"
    )
    
    let completedSets: [UUID: [ExerciseSet]] = [
        sampleExercise.id: [
            ExerciseSet(index: 1, weight: 50, reps: 8, done: true),
            ExerciseSet(index: 2, weight: 50, reps: 8, done: true),
            ExerciseSet(index: 3, weight: 50, reps: 7, done: true)
        ]
    ]
    
    ScrollView {
        ExercisePageView(
            exercise: sampleExercise,
            completed: completedSets,
            weightUnit: .lb,
            lastReps: [1: 8, 2: 8, 3: 7],
            hasBaseline: true,
            isActive: false,
            onAddSet: { },
            onSkipSet: { _ in },
            onDeleteSet: { _ in },
            onCommitInline: { _, _, _, _ in }
        )
    }
    .background(Color.black)
}