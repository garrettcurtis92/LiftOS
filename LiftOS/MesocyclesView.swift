//
//  MesocyclesView.swift
//  LiftOS
//
//  Created by Garrett Curtis on 9/13/25.
//
import SwiftUI

struct MesocyclesView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Current") {
                    NavigationLink {
                        Text("Mesocycle Detail (W1–W6)")
                            .padding()
                    } label: {
                        VStack(alignment: .leading) {
                            Text("Push/Pull/Legs (5+1 Deload)")
                                .font(.headline)
                            Text("Week 1 • 3 RIR • 5 days/wk")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Section("Templates") {
                    Text("Full Body (Upper Focus)")
                    Text("Upper/Lower (4-day)")
                    Text("PPL (6-day)")
                }
            }
            .navigationTitle("Mesocycles")
        }
    }
}
