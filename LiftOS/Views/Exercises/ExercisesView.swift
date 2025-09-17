// Exercises feature root
import SwiftUI

struct ExercisesView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Spacer()
                
                Text("No custom exercises yet")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.secondary)
                
                Text("Add your own exercises to track progress and create custom workouts.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Exercises")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        // TODO: Add action to create custom exercise
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .accessibilityLabel("Add exercise")
                }
            }
        }
    }
}
