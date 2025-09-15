//
//  ExercisesView.swift
//  LiftOS
//
//  Created by Garrett Curtis on 9/13/25.
//
import SwiftUI

struct ExercisesView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Chest") {
                    Text("Barbell Bench Press")
                    Text("Dumbbell Incline Press")
                    Text("Cable Fly")
                }
                Section("Back") {
                    Text("Lat Pulldown")
                    Text("Seated Cable Row")
                    Text("Deadlift")
                }
            }
            .navigationTitle("Exercises")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.tap()
                        // Add custom exercise flow (later)
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add Exercise")
                }
            }
        }
    }
}
