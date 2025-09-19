//
//  AddExerciseView.swift
//  LiftOS
//
//  Created by Garrett Curtis on 9/17/25.
//
// AddExerciseView.swift
import SwiftUI

struct AddExerciseView: View {
    // Callback to create the exercise in the store
    let onSave: (String, Exercise.MuscleGroup, Exercise.ExerciseType, String?) -> Void
    @Environment(\.dismiss) private var dismiss

    // Form state
    @State private var name: String = ""
    @State private var muscleGroup: Exercise.MuscleGroup = .chest
    @State private var type: Exercise.ExerciseType = .machine
    @State private var youtubeVideoID: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Basics") {
                    TextField("Name (e.g., Cable Fly)", text: $name)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()

                    Picker("Muscle Group", selection: $muscleGroup) {
                        ForEach(Exercise.MuscleGroup.allCases, id: \.rawValue) { mg in
                            Text(mg.rawValue.capitalized).tag(mg)
                        }
                    }

                    Picker("Exercise Type", selection: $type) {
                        ForEach(Exercise.ExerciseType.allCases, id: \.rawValue) { t in
                            Text(readableType(t)).tag(t)
                        }
                    }
                }

                Section("Optional") {
                    TextField("YouTube Video ID", text: $youtubeVideoID)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.asciiCapable)
                        .placeholder(when: youtubeVideoID.isEmpty) {
                            Text("").foregroundStyle(.secondary)
                        }
                }
            }
            .navigationTitle("New Exercise")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        onSave(trimmed, muscleGroup, type, youtubeVideoID.isEmpty ? nil : youtubeVideoID)
                        dismiss()
                        // (Later) add light haptic here on success.
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func readableType(_ t: Exercise.ExerciseType) -> String {
        switch t {
        case .machine: return "Machine"
        case .barbell: return "Barbell"
        case .smithMachine: return "Smith Machine"
        case .dumbbell: return "Dumbbell"
        case .cable: return "Cable / Free Motion"
        case .bodyweightOnly: return "Bodyweight Only"
        case .bodyweightLoadable: return "Bodyweight Loadable"
        case .machineAssistance: return "Machine Assistance"
        }
    }
}

// Small helper for placeholder hint styling
private extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}
