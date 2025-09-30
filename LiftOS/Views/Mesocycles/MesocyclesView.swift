import SwiftUI
import SwiftData

struct MesocyclesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Mesocycle.createdAt, order: .reverse)]) private var mesocycles: [Mesocycle]
    let onOpenTrain: (UUID) -> Void
    // TODO: replace with SwiftData fetch
    @State private var showCreate = false
    @State private var pendingDelete: Mesocycle? = nil
    @State private var renaming: Mesocycle? = nil
    @State private var newName: String = ""
    @State private var errorMessage: String? = nil
    @State private var fullyCompleted: [Mesocycle] = []
    // Derived bindings and helpers to simplify type-checking
    private var deleteAlertBinding: Binding<Bool> {
        Binding(
            get: { pendingDelete != nil },
            set: { if !$0 { pendingDelete = nil } }
        )
    }
    
    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }
    
    private var mesoIDs: [UUID] {
        mesocycles.map { $0.id }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if mesocycles.isEmpty {
                    VStack(spacing: 16) {
                        Text("Create a Mesocycle to get started!")
                            .font(.title3.weight(.semibold))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Button { showCreate = true } label: { Label("Create Mesocycle", systemImage: "plus") }
                            .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                } else {
                    List {
                        if !fullyCompleted.isEmpty {
                            Section {
                                ForEach(fullyCompleted) { meso in
                                    HStack(alignment: .firstTextBaseline) {
                                        Image(systemName: "checkmark.seal.fill").foregroundStyle(.green)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("All sessions complete")
                                                .font(.subheadline.weight(.semibold))
                                            Text("\(meso.name) is finished. Start your next mesocycle.")
                                                .font(.footnote)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Button("Create Mesocycle") { showCreate = true }
                                            .buttonStyle(.borderedProminent)
                                    }
                                }
                            }
                        }
                        ForEach(mesocycles) { meso in
                            Button { onOpenTrain(meso.id) } label: {
                                MesocycleRowView(
                                    item: MesocycleItem(
                                        id: meso.id,
                                        name: meso.name,
                                        weekCount: meso.weekCount,
                                        daysPerWeek: meso.daysPerWeek,
                                        isCurrent: meso.isCurrent,
                                        isCompleted: meso.isCompleted
                                    ),
                                    onNewNote: {  },
                                    onRename: { renaming = meso; newName = meso.name },
                                    onCopy: { copy(meso) },
                                    onSummary: {  },
                                    onSaveTemplate: {  },
                                    onDelete: { pendingDelete = meso }
                                )
                            }
                            .buttonStyle(.plain)
                            .contentShape(Rectangle())
                        }
                    }
                }
            }
            .navigationTitle("Mesocycles")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCreate = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Create mesocycle")
                }
            }
            .navigationDestination(isPresented: $showCreate) {
                CreateNewMesoView()
            }
            .task(id: mesoIDs) {
                recomputeCompletion()
            }
            .sheet(item: $renaming) { m in
                NavigationStack {
                    Form {
                        Section("Rename Mesocycle") {
                            TextField("Name", text: $newName)
                                .textInputAutocapitalization(.words)
                        }
                    }
                    .navigationTitle("Rename")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) { Button("Cancel") { renaming = nil } }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                                guard !trimmed.isEmpty else { return }
                                m.name = trimmed
                                try? modelContext.save()
                                renaming = nil
                            }
                            .disabled(newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                }
            }
            .alert("Delete Mesocycle?", isPresented: deleteAlertBinding) {
                Button("Cancel", role: .cancel) { pendingDelete = nil }
                Button("Delete", role: .destructive) {
                    if let m = pendingDelete {
                        delete(m)
                        pendingDelete = nil
                    }
                }
            } message: {
                if let m = pendingDelete { Text("This will remove \"\(m.name)\". This cannot be undone.") } else { Text("This cannot be undone.") }
            }
            .alert("Error", isPresented: errorAlertBinding) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "")
            }
        }
        
    }
    
    private func recomputeCompletion() {
        // Recompute fully completed mesocycles and mark their status
        var newlyCompleted: [Mesocycle] = []
        for meso in mesocycles {
            if let _ = MesoProgress.nextPosition(for: meso.id, in: modelContext, daysPerWeek: meso.daysPerWeek, weekCount: meso.weekCount) {
                // Has more to do
                if meso.isCompleted { meso.isCompleted = false }
            } else {
                // Fully completed
                newlyCompleted.append(meso)
                if !meso.isCompleted { meso.isCompleted = true }
            }
        }
        fullyCompleted = newlyCompleted
        if modelContext.hasChanges { try? modelContext.save() }
    }
    
    private func delete(_ meso: Mesocycle) {
        // Delete linked completion records
        let targetID: UUID = meso.id
        let d = FetchDescriptor<MesoCompletion>(predicate: #Predicate<MesoCompletion> { $0.mesocycleID == targetID })
        if let recs = try? modelContext.fetch(d) {
            for r in recs { modelContext.delete(r) }
        }
        modelContext.delete(meso)
        try? modelContext.save()
#if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
#endif
    }
    
    private func copy(_ meso: Mesocycle) {
        let dup = Mesocycle(name: meso.name + " Copy", weekCount: meso.weekCount, daysPerWeek: meso.daysPerWeek, isCurrent: false, isCompleted: false)
        // Duplicate days and selections
        for day in meso.days.sorted(by: { $0.index < $1.index }) {
            let newDay = MesoDay(index: day.index)
            newDay.mesocycle = dup
            for sel in day.selections {
                let newSel = MesoSelection(muscleGroupRaw: sel.muscleGroupRaw, exercise: sel.exercise)
                newSel.day = newDay
                newDay.selections.append(newSel)
            }
            dup.days.append(newDay)
        }
        modelContext.insert(dup)
        do {
            try modelContext.save()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

