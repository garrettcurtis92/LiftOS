//
//  CreateNewMeso.swift
//  LiftOS
//
//  Created by Garrett Curtis on 9/19/25.
//
import SwiftUI

struct CreateNewMesoView: View {
    @Environment(\.dismiss) private var dismiss

    // Minimal skeleton state
    @State private var name: String = ""
    @State private var weeks: Int = 4
    @State private var daysPerWeek: Int = 4
    @State private var deloadAtEnd: Bool = true
    @State private var labelStyle: LabelStyle = .weekdays

    var body: some View {
        Form {
            Section("Basics") {
                TextField("Mesocycle name", text: $name)
                    .textInputAutocapitalization(.words)

                Stepper(value: $weeks, in: 3...12) {
                    LabeledContent("Weeks", value: weeks.formatted())
                }
                Stepper(value: $daysPerWeek, in: 2...6) {
                    LabeledContent("Days / week", value: daysPerWeek.formatted())
                }
            }

            Section("Options") {
                Toggle("Deload in final week", isOn: $deloadAtEnd)
                Picker("Label style", selection: $labelStyle) {
                    Text("Weekdays").tag(LabelStyle.weekdays)
                    Text("Generic (Day 1, Day 2)").tag(LabelStyle.generic)
                }
            }

            Section("Template") {
                // Placeholder cards — you can replace with a nice Grid later
                NavigationLink("Start from scratch") {
                    MesoScratchBuilderView(daysPerWeek: daysPerWeek)}
                NavigationLink("Start with a template") { Text("Template picker (placeholder)") }
                NavigationLink("Copy an existing mesocycle") { Text("Copy (placeholder)") }
            }
        }
        .navigationTitle("Create Mesocycle")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") { /* hook up save later */ }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    enum LabelStyle: String, CaseIterable, Identifiable {
        case weekdays, generic
        var id: String { rawValue }
        
    }
    
}

