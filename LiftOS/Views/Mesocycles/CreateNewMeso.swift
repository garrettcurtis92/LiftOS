//
//  CreateNewMeso.swift
//  LiftOS
//
//  Created by Garrett Curtis on 9/19/25.
//
import SwiftUI

struct CreateNewMesoView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var weeks: Int = 4
    @State private var daysPerWeek: Int = 4
    @State private var deloadAtEnd: Bool = true
    @State private var labelStyle: LabelStyle = .weekdays
    
    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
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
                    Toggle("Deload in final week", isOn: $deloadAtEnd)
                        .font(.body)
                    
                    Picker("Label style", selection: $labelStyle) {
                        ForEach(LabelStyle.allCases) { style in
                            Text(style.title)
                                .font(.body)
                                .tag(style)
                        }
                    }
                    .font(.body)
                } header: {
                    Text("Options")
                        .font(.headline)
                }

                Section {
                    NavigationLink {
                        MesoScratchBuilderView(
                            name: name,
                            weeks: weeks,
                            daysPerWeek: daysPerWeek,
                            onComplete: { dismiss() }
                        )
                    } label: {
                        Text("Start from scratch")
                            .font(.body)
                    }
                    
                    NavigationLink {
                        Text("Template picker (placeholder)")
                    } label: {
                        Text("Start with a template")
                            .font(.body)
                    }
                    
                    NavigationLink {
                        Text("Copy existing (placeholder)")
                    } label: {
                        Text("Copy an existing mesocycle")
                            .font(.body)
                    }
                } header: {
                    Text("Template")
                        .font(.headline)
                }
            }
            .scrollContentBackground(.hidden)
            .background(DS.groupBg)
            .navigationTitle("Create Mesocycle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!isValid)
                }
            }
        }
    }
    
    private func save() {
        // TODO: Implement save logic or navigate to builder
        dismiss()
    }

    enum LabelStyle: String, CaseIterable, Identifiable {
        case weekdays, generic
        
        var id: String { rawValue }
        
        var title: String {
            switch self {
            case .weekdays: return "Weekdays"
            case .generic: return "Generic (Day 1, Day 2)"
            }
        }
    }
}

