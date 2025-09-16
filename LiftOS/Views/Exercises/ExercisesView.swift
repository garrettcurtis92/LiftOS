// Exercises feature root
import SwiftUI

struct ExercisesView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Chest") { Text("Barbell Bench Press"); Text("Dumbbell Incline Press"); Text("Cable Fly") }
                Section("Back") { Text("Lat Pulldown"); Text("Seated Cable Row"); Text("Deadlift") }
            }
            .navigationTitle("Exercises")
        }
    }
}
