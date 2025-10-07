// ExerciseView.swift
import SwiftUI
import SwiftData

struct ExerciseView: View {
    @Environment(\.modelContext) private var modelContext
    private var store: ExerciseStore { ExerciseStore(modelContext: modelContext) }
    
    @State private var customs: [Exercise] = []
    @State private var searchQuery = ""
    @State private var showAddSheet = false
    @State private var showFiltersSheet = false
    @State private var errorMessage: String?
    @State private var selectedExercise: Exercise?
    @State private var showEditSheet = false
    @State private var showNoteSheet = false
    @State private var selectedMuscleGroup: Exercise.MuscleGroup? = nil
    @State private var selectedType: Exercise.ExerciseType? = nil
    @State private var pendingDelete: Exercise? = nil

    private var filteredExercises: [Exercise] {
        var result = customs
        
        // Apply muscle group filter
        if let mg = selectedMuscleGroup {
            result = result.filter { $0.muscleGroup == mg }
        }
        
        // Apply type filter
        if let t = selectedType {
            result = result.filter { $0.type == t }
        }
        
        // Apply search query
        if !searchQuery.isEmpty {
            result = result.filter { exercise in
                exercise.name.localizedCaseInsensitiveContains(searchQuery) ||
                String(describing: exercise.muscleGroup).localizedCaseInsensitiveContains(searchQuery)
            }
        }
        
        return result
    }
    
    private var hasActiveFilters: Bool {
        selectedMuscleGroup != nil || selectedType != nil
    }

    var body: some View {
        NavigationStack {
            Group {
                if customs.isEmpty {
                    ContentUnavailableView(
                        "No Custom Exercises",
                        systemImage: "dumbbell",
                        description: Text("Tap the + to add your first custom exercise.")
                    )
                } else if filteredExercises.isEmpty {
                    ContentUnavailableView.search
                } else {
                    List {
                        ForEach(filteredExercises, id: \.persistentModelID) { ex in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(ex.name)
                                    .font(.headline)
                                
                                Text("\(String(describing: ex.muscleGroup)) • \(readableType(ex.type))")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)

                                // Latest note preview
                                if let latest = try? store.latestNote(for: ex), !latest.text.isEmpty {
                                    Text(latest.text)
                                        .font(.footnote)
                                        .lineLimit(1)
                                        .foregroundStyle(.secondary)
                                        .padding(.top, 2)
                                        .accessibilityLabel("Latest note: \(latest.text)")
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    pendingDelete = ex
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }

                                Button {
                                    selectedExercise = ex
                                    showEditSheet = true
                                } label: { Label("Edit", systemImage: "square.and.pencil") }

                                Button {
                                    selectedExercise = ex
                                    showNoteSheet = true
                                } label: { Label("Note", systemImage: "note.text") }
                            }
                            .contextMenu {
                                Button {
                                    selectedExercise = ex
                                    showEditSheet = true
                                } label: { Label("Edit Exercise", systemImage: "square.and.pencil") }

                                Button {
                                    selectedExercise = ex
                                    showNoteSheet = true
                                } label: { Label("Add Exercise Note", systemImage: "note.text") }

                                Divider()

                                Button(role: .destructive) {
                                    pendingDelete = ex
                                } label: {
                                    Label("Delete Exercise", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Exercises")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchQuery, placement: .navigationBarDrawer(displayMode: .always))
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button {
                        showFiltersSheet = true
                    } label: {
                        Image(systemName: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    }
                    .accessibilityLabel("Filter")
                    
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add Exercise")
                }
            }
            .task {
                try? reload()
            }
            .sheet(isPresented: $showFiltersSheet) {
                NavigationStack {
                    Form {
                        Section("Muscle Group") {
                            Button("All") {
                                selectedMuscleGroup = nil
                            }
                            ForEach(Exercise.MuscleGroup.allCases, id: \.self) { mg in
                                Button {
                                    selectedMuscleGroup = mg
                                } label: {
                                    HStack {
                                        Text(String(describing: mg).capitalized)
                                        Spacer()
                                        if selectedMuscleGroup == mg {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        }
                        
                        Section("Exercise Type") {
                            Button("All") {
                                selectedType = nil
                            }
                            ForEach(Exercise.ExerciseType.allCases, id: \.self) { type in
                                Button {
                                    selectedType = type
                                } label: {
                                    HStack {
                                        Text(readableType(type))
                                        Spacer()
                                        if selectedType == type {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        }
                        
                        if hasActiveFilters {
                            Section {
                                Button("Clear All Filters") {
                                    selectedMuscleGroup = nil
                                    selectedType = nil
                                    showFiltersSheet = false
                                }
                            }
                        }
                    }
                    .navigationTitle("Filters")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                showFiltersSheet = false
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddExerciseView { name, mg, type, yt in
                    do {
                        try store.addCustom(name: name, muscleGroup: mg, type: type, youtubeVideoID: yt)
                        try reload()
                    } catch { errorMessage = error.localizedDescription }
                }
                .presentationDetents([.medium, .large])
            }
            // Edit sheet
            .sheet(isPresented: $showEditSheet) {
                if let ex = selectedExercise {
                    EditExerciseView(
                        exercise: ex,
                        onSave: { name, mg, type, yt in
                            do {
                                try store.update(ex,
                                                 name: name,
                                                 muscleGroup: mg,
                                                 type: type,
                                                 youtubeVideoID: yt)
                                try reload()
                            } catch { errorMessage = error.localizedDescription }
                        }
                    )
                }
            }

            // Note sheet (placeholder persistence for now – we’ll wire SwiftData notes next)
            .sheet(isPresented: $showNoteSheet) {
                if let ex = selectedExercise {
                    AddExerciseNoteView(exercise: ex) { noteText in
                        do {
                            try store.addNote(for: ex, text: noteText)
                            try reload()
                        } catch { errorMessage = error.localizedDescription }
                    }
                }
            }
            .alert("Error", isPresented: Binding(get: { errorMessage != nil },
                                                 set: { if !$0 { errorMessage = nil } })) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "")
            }
            .alert("Delete Exercise?", isPresented: Binding(
                get: { pendingDelete != nil },
                set: { if !$0 { pendingDelete = nil } }
            )) {
                Button("Cancel", role: .cancel) { pendingDelete = nil }
                Button("Delete", role: .destructive) {
                    if let ex = pendingDelete {
                        do {
                            try store.delete(ex)
                            pendingDelete = nil
                            try reload()
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                    }
                }
            } message: {
                if let ex = pendingDelete {
                    Text("This will remove \"\(ex.name)\". This cannot be undone.")
                } else {
                    Text("This cannot be undone.")
                }
            }
        }
    }

    private func reload() throws {
        customs = try store.fetchCustoms()
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

struct EditExerciseView: View {
    let exercise: Exercise
    let onSave: (String, Exercise.MuscleGroup, Exercise.ExerciseType, String?) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var muscleGroup: Exercise.MuscleGroup
    @State private var type: Exercise.ExerciseType
    @State private var youtubeVideoID: String

    init(exercise: Exercise,
         onSave: @escaping (String, Exercise.MuscleGroup, Exercise.ExerciseType, String?) -> Void) {
        self.exercise = exercise
        self.onSave = onSave
        _name = State(initialValue: exercise.name)
        _muscleGroup = State(initialValue: exercise.muscleGroup)
        _type = State(initialValue: exercise.type)
        _youtubeVideoID = State(initialValue: exercise.youtubeVideoID ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Basics") {
                    TextField("Name", text: $name)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()

                    Picker("Muscle Group", selection: $muscleGroup) {
                        ForEach(Exercise.MuscleGroup.allCases, id: \.self) { mg in
                            Text(String(describing: mg).capitalized).tag(mg)
                        }
                    }

                    Picker("Exercise Type", selection: $type) {
                        ForEach(Exercise.ExerciseType.allCases, id: \.self) { t in
                            Text(readableType(t)).tag(t)
                        }
                    }
                }
                Section("Optional") {
                    TextField(
                        "YouTube Video ID",
                        text: $youtubeVideoID,
                        prompt: Text("e.g., dQw4w9WgXcQ").foregroundStyle(.secondary)
                    )
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.asciiCapable)
                }
            }
            .navigationTitle("Edit Exercise")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        onSave(trimmed, muscleGroup, type, youtubeVideoID.isEmpty ? nil : youtubeVideoID)
                        dismiss()
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

struct AddExerciseNoteView: View {
    let exercise: Exercise
    let onSave: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var text: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Note") {
                    TextField("Write a quick note…", text: $text, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Note")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        onSave(trimmed)
                        dismiss()
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

struct FilterChip: View {
    let title: String
    let onClear: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Text(title).font(.footnote)
            Image(systemName: "xmark.circle.fill")
                .imageScale(.small)
                .accessibilityLabel("Clear \(title)")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.thinMaterial, in: Capsule())
        .onTapGesture { onClear() }
    }
}

