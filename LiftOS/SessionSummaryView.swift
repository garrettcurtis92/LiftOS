//
//  SessionSummaryView.swift
//  LiftOS
//
//  Created by Garrett Curtis on 9/13/25.
//
import SwiftUI

struct SessionSummaryView: View {
    let summary: SessionSummary
    @AppStorage("weightUnit") private var weightUnit: WeightUnit = .lb

    var body: some View {
        List {
            Section("Overview") {
                HStack { Text("Session"); Spacer(); Text(summary.title).foregroundStyle(.secondary) }
                HStack { Text("Date"); Spacer(); Text(summary.date.formatted(date: .abbreviated, time: .shortened)).foregroundStyle(.secondary) }
                HStack { Text("Total Sets"); Spacer(); Text("\(summary.totalSets)").foregroundStyle(.secondary) }
                HStack { Text("Total Volume"); Spacer(); Text(String(format: "%.0f %@", summary.totalVolume, weightUnit.display)).foregroundStyle(.secondary) }
            }

            ForEach(groupedByExercise(), id: \.key) { name, sets in
                Section(name) {
                    ForEach(sets) { s in
                        HStack {
                            Text("Set \(s.index)")
                            Spacer()
                            Text("\(s.reps ?? 0)x \(Int(s.weight ?? 0)) \(weightUnit.display)  RIR \(s.rir ?? 0)")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .monospaced()
                        }
                    }
                }
            }
        }
        .navigationTitle("Summary")
    }

    private func groupedByExercise() -> [(key: String, value: [CompletedSet])] {
        let dict = Dictionary(grouping: summary.sets, by: { $0.exerciseName })
        return dict.sorted { $0.key < $1.key }
    }
}
