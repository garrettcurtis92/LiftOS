//
//  MesocycleEditorView.swift
//  LiftOS
//
//  Created by Garrett Curtis on 10/6/25.
//

import SwiftUI
import SwiftData

struct MesocycleEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let meso: Mesocycle
    
    @State private var name: String = ""
    @State private var weeks: Int = 4
    @State private var daysPerWeek: Int = 4
    
    var isReadOnly: Bool { meso.isCompleted }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Form {
                    Section {
                        TextField("Mesocycle name", text: $name)
                            .font(.body)
                        
                        Stepper("Weeks: \(weeks)", value: $weeks, in: 1...16)
                            .font(.body)
                            .monospacedDigit()
                        
                        Stepper("Days / week: \(daysPerWeek)", value: $daysPerWeek, in: 1...7)
                            .font(.body)
                            .monospacedDigit()
                    } header: {
                        Text("Basics")
                            .font(.headline)
                    }
                    
                    Section {
                        LabeledContent("Created") {
                            Text(meso.createdAt, format: .dateTime)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        if let startDate = meso.startDate {
                            LabeledContent("Started") {
                                Text(startDate, format: .dateTime)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        LabeledContent("Status") {
                            switch meso.status {
                            case .current:
                                StatusChip(text: "CURRENT", tint: .blue)
                            case .completed:
                                StatusChip(text: "COMPLETED", tint: .green)
                            case .planned:
                                StatusChip(text: "PLANNED", tint: .orange)
                            }
                        }
                    } header: {
                        Text("Details")
                            .font(.headline)
                    }
                }
                .scrollContentBackground(.hidden)
                .background(DS.groupBg)
                .disabled(isReadOnly)
                
                // Read-only banner for completed mesocycles
                if isReadOnly {
                    VStack {
                        Label("Completed — read-only", systemImage: "checkmark.circle.fill")
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(.green)
                            .padding(10)
                            .background(.ultraThinMaterial, in: Capsule())
                            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                            .padding(.top, 8)
                        
                        Spacer()
                    }
                }
            }
            .navigationTitle(isReadOnly ? "View Mesocycle" : "Edit Mesocycle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if isReadOnly {
                    // Read-only toolbar
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { dismiss() }
                    }
                    
                    ToolbarItem(placement: .confirmationAction) {
                        Button {
                            copyMesocycle()
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                    }
                } else {
                    // Editable toolbar
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                    
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") { save() }
                            .disabled(!isValid)
                    }
                }
            }
            .onAppear {
                // Load mesocycle data
                name = meso.name
                weeks = meso.weekCount
                daysPerWeek = meso.daysPerWeek
            }
        }
    }
    
    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func save() {
        guard !isReadOnly else { return }
        
        meso.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        meso.weekCount = weeks
        meso.daysPerWeek = daysPerWeek
        
        try? modelContext.save()
        dismiss()
    }
    
    /// Creates a duplicate template from a mesocycle (base properties only)
    private func duplicateTemplate(from source: Mesocycle) {
        let duplicate = Mesocycle(
            name: "\(source.name) Copy",
            weekCount: source.weekCount,
            daysPerWeek: source.daysPerWeek,
            status: .planned,
            createdAt: Date(),
            startDate: nil
        )
        
        modelContext.insert(duplicate)
        try? modelContext.save()
    }
    
    private func copyMesocycle() {
        let copy = Mesocycle(
            name: "\(meso.name) Copy",
            weekCount: meso.weekCount,
            daysPerWeek: meso.daysPerWeek,
            status: .planned
        )
        
        // Copy the plan snapshot
        copy.planSnapshot = meso.planSnapshot
        
        // Copy days and selections
        for day in meso.days.sorted(by: { $0.index < $1.index }) {
            let newDay = MesoDay(index: day.index)
            newDay.mesocycle = copy
            for sel in day.selections {
                let newSel = MesoSelection(muscleGroupRaw: sel.muscleGroupRaw, exercise: sel.exercise)
                newSel.day = newDay
                newDay.selections.append(newSel)
                modelContext.insert(newSel)
            }
            copy.days.append(newDay)
            modelContext.insert(newDay)
        }
        
        modelContext.insert(copy)
        try? modelContext.save()
        
        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Mesocycle.self, configurations: config)
    
    let meso = Mesocycle(
        name: "Sample Mesocycle",
        weekCount: 6,
        daysPerWeek: 4,
        status: .completed
    )
    container.mainContext.insert(meso)
    
    return MesocycleEditorView(meso: meso)
        .modelContainer(container)
}
