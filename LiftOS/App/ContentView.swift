import SwiftUI
import SwiftData

struct ContentView: View {
    
    private enum AppTab: Hashable {
        case train, mesocycles, exercises, more
    }
    
    @AppStorage("accentChoice") private var accentChoiceRaw: String = AccentChoice.multicolor.rawValue
    @State private var searchText: String = ""
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab: AppTab = .train
    @State private var selectedMesocycleID: UUID? = nil
    @State private var didResolveCurrentMesoOnLaunch = false
    
    // New Assistant Orb Controller (replaces old chat sheet state)
    @StateObject private var orbController = OrbController()
    
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
                TrainView(
                    mesocycleID: selectedMesocycleID,
                    onGoToMesocycles: { selectedTab = .mesocycles },
                    onClearActiveMesocycle: { selectedMesocycleID = nil }
                )
            }
            .task {
                guard !didResolveCurrentMesoOnLaunch else { return }
                didResolveCurrentMesoOnLaunch = true
                // Fetch current mesocycle and set selectedMesocycleID
                // Note: Can't use enum in predicate, fetch all and filter
                let descriptor = FetchDescriptor<Mesocycle>()
                if let current = try? modelContext.fetch(descriptor).first(where: { $0.isCurrent }) {
                    selectedMesocycleID = current.id
                }
            }
            .tabItem { Label("Train", systemImage: "dumbbell") }
            .tag(AppTab.train)
            .overlay(alignment: .top) { orbOverlay(for: "train") }
            
            // MESOCYCLES
            MesocyclesView(onOpenTrain: { id in
                selectedMesocycleID = id
                selectedTab = .train
            })
            .tabItem { Label("Mesocycles", systemImage: "chart.line.uptrend.xyaxis") }
            .tag(AppTab.mesocycles)
            .overlay(alignment: .top) { orbOverlay(for: "mesocycles") }
            .onChange(of: selectedTab) { _, newTab in
                // When returning to Train, ensure selected mesocycle still exists
                guard newTab == .train else { return }
                if let id = selectedMesocycleID {
                    let descriptor = FetchDescriptor<Mesocycle>(predicate: #Predicate { $0.id == id })
                    let exists = (try? modelContext.fetch(descriptor))?.first != nil
                    if !exists { selectedMesocycleID = nil }
                }
            }
            
            // EXERCISES
            ExerciseView()
                .searchable(text: $searchText)
                .task { await seedPrefillCatalogIfNeeded(modelContext) }
                .tabItem { Label("Exercises", systemImage: "books.vertical") }
                .tag(AppTab.exercises)
                .overlay(alignment: .top) { orbOverlay(for: "exercises") }
            
            // MORE
            MoreView()
                .tabItem { Label("More", systemImage: "gear") }
                .tag(AppTab.more)
                .overlay(alignment: .top) { orbOverlay(for: "more") }
        }
        .tint(selectedAccentColor ?? MulticolorAccent.color(for: .navigation))
        .fitnessNavigationStyle()
        .environmentObject(orbController)
        .sheet(isPresented: $orbController.isPresentingSheet) {
            AssistantSheetView()
                .presentationDetents([.fraction(0.55), .large])
                .presentationBackgroundInteraction(.enabled(upThrough: .fraction(0.55)))
        }
    }
    
    // MARK: - Assistant Orb Overlay
    
    @ViewBuilder
    private func orbOverlay(for key: String) -> some View {
        // Top-level overlay so the orb floats above content but under system alerts
        AssistantOrb(tabKey: key)
            .padding(.bottom, 8) // minor spacing from bottom bars when near
            .padding(.top, 0)
            .allowsHitTesting(true)
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

