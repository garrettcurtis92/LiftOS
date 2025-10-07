import SwiftUI
import SwiftData

struct MesocyclesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Mesocycle.createdAt, order: .reverse)]) private var mesocycles: [Mesocycle]
    let onOpenTrain: (UUID) -> Void
    @State private var showCreate = false
    @State private var pendingDelete: Mesocycle? = nil
    @State private var renaming: Mesocycle? = nil
    @State private var newName: String = ""
    @State private var errorMessage: String? = nil
    @State private var fullyCompleted: [Mesocycle] = []
    
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
                    .background(DS.groupBg)
                } else {
                    List {
                        // Completion Banner
                        if !fullyCompleted.isEmpty {
                            Section {
                                ForEach(fullyCompleted) { meso in
                                    DSCard {
                                        HStack(spacing: 12) {
                                            Image(systemName: "checkmark.seal.fill")
                                                .imageScale(.large)
                                                .symbolRenderingMode(.palette)
                                                .foregroundStyle(.white, .green)
                                                .accessibilityHidden(true)
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("All sessions complete")
                                                    .font(.headline)
                                                Text("\(meso.name) is finished. Start your next mesocycle.")
                                                    .font(.subheadline)
                                                    .foregroundStyle(.secondary)
                                            }
                                            Spacer()
                                            Button("Create Mesocycle") { showCreate = true }
                                                .buttonStyle(.borderedProminent)
                                        }
                                    }
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                                }
                            }
                        }
                        
                        // Mesocycle List
                        Section {
                            ForEach(mesocycles) { meso in
                                NavigationLink(value: meso) {
                                    HStack(spacing: 12) {
                                        VStack(alignment: .leading, spacing: 6) {
                                            HStack {
                                                Text(meso.name)
                                                    .font(.headline)
                                                Spacer()
                                                switch meso.status {
                                                case .current:
                                                    StatusChip(text: "CURRENT", tint: .blue)
                                                case .completed:
                                                    StatusChip(text: "COMPLETED", tint: .green)
                                                case .planned:
                                                    EmptyView()
                                                }
                                            }
                                            Text("\(meso.weekCount) \(meso.weekCount == 1 ? "week" : "weeks") – \(meso.daysPerWeek) days/week")
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                            
                                            // Start Training button for current mesocycle
                                            if meso.isCurrent && !meso.isCompleted {
                                                Button {
                                                    onOpenTrain(meso.id)
                                                } label: {
                                                    HStack {
                                                        Image(systemName: "figure.strengthtraining.traditional")
                                                        Text("Start Training")
                                                    }
                                                    .font(.subheadline.weight(.medium))
                                                    .foregroundStyle(.white)
                                                    .frame(maxWidth: .infinity)
                                                    .padding(.vertical, 8)
                                                    .background(.blue.gradient, in: RoundedRectangle(cornerRadius: 8))
                                                }
                                                .buttonStyle(.plain)
                                                .padding(.top, 4)
                                            }
                                        }
                                    }
                                }
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .contextMenu {
                                    Button("Rename", systemImage: "pencil") {
                                        renaming = meso
                                        newName = meso.name
                                    }
                                    Button("Duplicate", systemImage: "plus.square.on.square") {
                                        copy(meso)
                                    }
                                    Button(role: .destructive) {
                                        pendingDelete = meso
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        pendingDelete = meso
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    
                                    if !meso.isCompleted {
                                        Button {
                                            MesocycleStore.markCompleted(meso, in: modelContext)
                                        } label: {
                                            Label("Complete", systemImage: "checkmark.circle.fill")
                                        }
                                        .tint(.green)
                                    }
                                    
                                    if !meso.isCurrent {
                                        Button {
                                            MesocycleStore.setCurrent(meso, in: modelContext)
                                            onOpenTrain(meso.id)
                                        } label: {
                                            Label("Set Current", systemImage: "flag.checkered")
                                        }
                                        .tint(.blue)
                                    }
                                }
                                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                    if meso.isCompleted {
                                        Button {
                                            copy(meso)
                                        } label: {
                                            Label("Copy", systemImage: "doc.on.doc")
                                        }
                                        .tint(.indigo)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(DS.groupBg)
                }
            }
            .navigationTitle("Mesocycles")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
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
            .navigationDestination(for: Mesocycle.self) { meso in
                MesocycleEditorView(meso: meso)
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
                if meso.isCompleted { meso.status = .current }
            } else {
                // Fully completed - mark as completed if not already
                if !meso.isCompleted { meso.status = .completed }
                // Only show in completion banner if actually marked as completed
                if meso.isCompleted {
                    newlyCompleted.append(meso)
                }
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
        let dup = Mesocycle(name: meso.name + " Copy", weekCount: meso.weekCount, daysPerWeek: meso.daysPerWeek, status: .planned)
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

