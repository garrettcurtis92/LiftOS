import SwiftUI

struct NewMesoView: View {
    let mode: MesocycleEntryView.StartMode

    @State private var draft: MesoDraft = .default()

    var body: some View {
        List {
            Section("Weeks") {
                Stepper(value: $draft.weeks, in: 4...8) {
                    Text("\(draft.weeks) weeks")
                }
                Toggle(isOn: $draft.hasDeloadAtEnd) {
                    Text("Deload in last week")
                }
            }

            Section("Days per week") {
                Picker("Labels", selection: $draft.labelStyle) {
                    Text("Generic (Day 1/2/3)").tag(DayLabelStyle.generic)
                    Text("Weekdays (Mon/Tue…)").tag(DayLabelStyle.weekdays)
                }
                .pickerStyle(.menu)

                Stepper(value: $draft.daysPerWeek, in: 2...6, step: 1) {
                    Text("\(draft.daysPerWeek) days / week")
                }
                .onChange(of: draft.daysPerWeek) { _, newValue in
                    let names = DayDraft.defaultDays(count: newValue, style: draft.labelStyle)
                    // preserve existing exercises where possible
                    var newDays: [DayDraft] = names.enumerated().map { ix, base in
                        if ix < draft.days.count {
                            var copy = draft.days[ix]
                            copy.name = base.name
                            return copy
                        } else {
                            return base
                        }
                    }
                    draft.days = Array(newDays.prefix(newValue))
                }

                // Label style change relabels existing
                .onChange(of: draft.labelStyle) { _, style in
                    let names = DayDraft.defaultDays(count: draft.daysPerWeek, style: style)
                    for i in draft.days.indices {
                        draft.days[i].name = names[i].name
                    }
                }
            }

            Section("Days") {
                ForEach($draft.days) { $day in
                    NavigationLink(value: day.id) {
                        HStack {
                            Text(day.name)
                            Spacer()
                            Text("\(day.exerciseRefs.count) exercises")
                                .foregroundStyle(.secondary)
                                .font(.footnote)
                        }
                    }
                }
                .onDelete { idx in draft.days.remove(atOffsets: idx) }
                .onMove { src, dst in draft.days.move(fromOffsets: src, toOffset: dst) }

                Button {
                    guard draft.daysPerWeek < 6 else { return }
                    draft.daysPerWeek += 1
                } label: {
                    Label("Add Day", systemImage: "plus.circle.fill")
                }
                .disabled(draft.daysPerWeek >= 6)
            }

            Section {
                HStack {
                    Button(role: .destructive) { draft = .default() } label: {
                        Label("Clear Board", systemImage: "trash")
                    }
                    Spacer()
                    Button {
                        // Save and dismiss
                        ActiveMesocycleStore.shared.save(draft)
                    } label: {
                        Label("Save", systemImage: "checkmark.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .navigationTitle("New Mesocycle")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { EditButton() }
        }
        // TODO: NavigationDestination for Day Editor (next step)
    }
}