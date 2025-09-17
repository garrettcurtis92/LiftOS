import SwiftUI

struct MesocyclesView: View {
    @State private var showBuilder = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Spacer()

                Text("No mesocycles yet")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text("Create a plan to unlock the calendar and auto-progression.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("Mesocycles")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        // TODO: Add action to create mesocycle
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .accessibilityLabel("New mesocycle")
                }
            }
            .sheet(isPresented: $showBuilder) {
                NavigationStack {
                    
                }
                .presentationDetents([.large])
                .presentationCornerRadius(20)
            }
            .background(WorkoutBackground().ignoresSafeArea())
        }
    }
}
