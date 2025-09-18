import SwiftUI
import SwiftData

@main
struct LiftOSApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Exercise.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: false)
        return try! ModelContainer(for: schema, configurations: config)
    }()

    var body: some Scene {
        WindowGroup {
            ContentView() // Temp entry for this focused work
                .modelContainer(sharedModelContainer)
                .task {
                    // Seed on first launch
                    let context = sharedModelContainer.mainContext
                    let store = ExerciseStore(modelContext: context)
                    try? store.seedIfNeeded()
                }
        }
    }
}
