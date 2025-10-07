import SwiftUI
import SwiftData

@main
struct LiftOSApp: App {
    let sharedModelContainer: ModelContainer = {
           let schema = Schema([
               Exercise.self,
               ExerciseNote.self,
               Mesocycle.self,
               MesoDay.self,
               MesoSelection.self,
               MesoCompletion.self,
               WorkoutLogEntry.self,
           ])
           let config = ModelConfiguration(isStoredInMemoryOnly: false)
           do {
               return try ModelContainer(for: schema, configurations: config)
           } catch {
               assertionFailure("Failed to load ModelContainer: \(error)")
               fatalError("Unrecoverable SwiftData error")
           }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView() // Temp entry for this focused work
                .modelContainer(sharedModelContainer)
                .dynamicTypeSize(...DynamicTypeSize.accessibility5) // Full Dynamic Type & accessibility support
                .task {
                    // Seed on first launch
                    let context = sharedModelContainer.mainContext
                    let store = ExerciseStore(modelContext: context)
                    try? store.seedIfNeeded()
                }
        }
    }
}



#Preview("LiftOSApp") {
    ContentView()
}
