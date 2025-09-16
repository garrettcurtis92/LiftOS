import SwiftUI
struct MesocyclesView: View {
    @State private var showBuilder = false
    @State private var activeDraft: MesoDraft? = ActiveMesocycleStore.shared.load()

    var body: some View {
        NavigationStack {
            List {
                // Current (or empty state)
                Section("Current") {
                    if let draft = activeDraft {
                        NavigationLink {
                            // Placeholder detail for now
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Weeks: \(draft.weeks) \(draft.hasDeloadAtEnd ? "(Deload in last week)" : "")")
                                Text("Days/week: \(draft.daysPerWeek)")
                                Text("Labels: \(draft.labelStyle == .weekdays ? "Weekdays" : "Generic")")
                            }
                            .padding()
                            .navigationTitle("Active Mesocycle")
                            .navigationBarTitleDisplayMode(.inline)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Active plan")
                                    .font(.headline)
                                Text("\(draft.daysPerWeek) days/wk • \(draft.weeks) weeks")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .listRowBackground(Color.clear)
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("No active mesocycle")
                                .font(.headline)
                            Text("Create a cycle to unlock the calendar and auto-progression.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Button {
                                showBuilder = true
                            } label: {
                                Text("Build Mesocycle")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(Color.accentColor)
                            .padding(.top, 4)
                        }
                        .listRowBackground(Color.clear)
                    }
                }

                // Build entry
                Section("Build") {
                    NavigationLink("Build Mesocycle") { MesocycleEntryView() }
                        .listRowBackground(Color.clear)
                }

                // Templates (static placeholders for now)
                Section("Templates") {
                    Text("Full Body (Upper Focus)")
                    Text("Upper/Lower (4-day)")
                    Text("PPL (6-day)")
                }
            }
            .navigationTitle("Mesocycles")
            // Toolbar removed per instructions; no plus or calendar/day icons remain.
            .sheet(isPresented: $showBuilder, onDismiss: {
                // Refresh active draft when builder closes
                activeDraft = ActiveMesocycleStore.shared.load()
            }) {
                NavigationStack { MesocycleEntryView() }
                    .presentationDetents([.large])
                    .presentationCornerRadius(20)
            }
            .onAppear { activeDraft = ActiveMesocycleStore.shared.load() }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(WorkoutBackground())
        }
    }
}