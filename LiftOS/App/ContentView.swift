import SwiftUI
import SwiftData

struct ContentView: View {
    
    private enum AppTab: Hashable {
        case train, mesocycles, exercises, more, chat
    }
    
    @AppStorage("accentChoice") private var accentChoiceRaw: String = AccentChoice.multicolor.rawValue
    @State private var searchText: String = ""
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab: AppTab = .train
    @State private var selectedMesocycleID: UUID? = nil
    
    private var selectedAccentColor: Color? {
        let choice = AccentChoice(rawValue: accentChoiceRaw) ?? .multicolor
        if choice == .multicolor {
            // Return nil to let individual components handle their own multicolor logic
            return nil
        } else {
            return choice.color
        }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // TRAIN
            NavigationStack {
                TrainView(mesocycleID: selectedMesocycleID)
                    .navigationTitle("Train")
                    .navigationBarTitleDisplayMode(.large)
            }
            .tabItem { Label("Train", systemImage: "dumbbell") }
            .tag(AppTab.train)
            
            // MESOCYCLES
            MesocyclesView(onOpenTrain: { id in
                selectedMesocycleID = id
                selectedTab = .train
            })
            .tabItem { Label("Mesocycles", systemImage: "chart.line.uptrend.xyaxis") }
            .tag(AppTab.mesocycles)
            
            // EXERCISES
            ExerciseView()
                .searchable(text: $searchText)
                .task { await seedPrefillCatalogIfNeeded(modelContext) }
                .tabItem { Label("Exercises", systemImage: "books.vertical") }
                .tag(AppTab.exercises)
            
            // MORE
            MoreView()
                .tabItem { Label("More", systemImage: "gear") }
                .tag(AppTab.more)
            
            // CHAT (detached feel)
            NavigationStack { ChatWindowView() }
                .tabItem { Label("Chat", systemImage: "bubble.left.and.bubble.right.fill") }
                .tag(AppTab.chat)
        }
    }
    
    // MARK: - Catalog Seeding Helper
    @State private var hasSeededPrefillCatalog = false
    
    @MainActor
    private func seedPrefillCatalogIfNeeded(_ modelContext: ModelContext) async {
        // Prevent duplicate seeding during app lifetime
        guard !hasSeededPrefillCatalog else { return }
        hasSeededPrefillCatalog = true
        
        // TODO: Implement real seeding logic using `modelContext`.
        // This stub intentionally no-ops to unblock compilation.
        // Example (replace with your actual implementation):
        // try? await PrefillCatalogSeeder.seedIfNeeded(in: modelContext)
    }
}

#Preview {
    ContentView()
}
