import SwiftUI

struct ReplaceExerciseSheet: View {
    @Environment(\.dismiss) private var dismiss
    let originalExercise: ExerciseItem
    let allExercises: [ExerciseProgressionRule]
    let onReplace: (String, ReplacementScope) -> Void
    
    @State private var selectedScope: ReplacementScope = .session
    @State private var searchText = ""
    @State private var selectedExercise: String?
    @State private var selectedMuscleGroup: String?
    
    private var originalMuscleGroup: String? {
        allExercises.first(where: { $0.name == originalExercise.name })?.muscleGroup
    }
    
    private var muscleGroups: [String] {
        let groups = Set(allExercises.map { $0.muscleGroup })
        return groups.sorted()
    }
    
    private var filteredExercises: [ExerciseProgressionRule] {
        var exercises = allExercises
        
        // Filter by muscle group
        if let muscleGroup = selectedMuscleGroup {
            exercises = exercises.filter { $0.muscleGroup == muscleGroup }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            exercises = exercises.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        return exercises.sorted { $0.name < $1.name }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Scope selector
                Picker("Replacement Scope", selection: $selectedScope) {
                    Text("Just This Session").tag(ReplacementScope.session)
                    Text("Rest of Mesocycle").tag(ReplacementScope.mesocycle)
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Description
                VStack(alignment: .leading, spacing: 8) {
                    if selectedScope == .session {
                        Label {
                            Text("One-time replacement. Next session will revert to **\(originalExercise.name)**. No progression tracking.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } icon: {
                            Image(systemName: "info.circle")
                                .foregroundStyle(.blue)
                        }
                    } else {
                        Label {
                            Text("Permanently replaces **\(originalExercise.name)** for this mesocycle. Progression starts fresh.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } icon: {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundStyle(.orange)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 12)
                
                Divider()
                
                // Muscle group filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        // "All" button
                        Button {
                            selectedMuscleGroup = nil
                        } label: {
                            Text("All")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(selectedMuscleGroup == nil ? .white : .primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(selectedMuscleGroup == nil ? Color.accentColor : Color(.systemGray5), in: Capsule())
                        }
                        .buttonStyle(.plain)
                        
                        ForEach(muscleGroups, id: \.self) { group in
                            Button {
                                selectedMuscleGroup = group
                            } label: {
                                Text(group.capitalized)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(selectedMuscleGroup == group ? .white : .primary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedMuscleGroup == group ? Color.accentColor : Color(.systemGray5), in: Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                
                Divider()
                
                // Exercise picker with search
                List(filteredExercises, id: \.name) { exercise in
                    Button {
                        selectedExercise = exercise.name
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(exercise.name)
                                    .foregroundStyle(.primary)
                                Text(exercise.equipType.rawValue.capitalized)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if selectedExercise == exercise.name {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
                .searchable(text: $searchText, prompt: "Search exercises")
            }
            .navigationTitle("Replace Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Replace") {
                        if let newExercise = selectedExercise {
                            onReplace(newExercise, selectedScope)
                            dismiss()
                        }
                    }
                    .disabled(selectedExercise == nil)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                // Pre-select the original exercise's muscle group
                if let originalGroup = originalMuscleGroup {
                    selectedMuscleGroup = originalGroup
                }
            }
        }
    }
}
