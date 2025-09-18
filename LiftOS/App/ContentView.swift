import SwiftUI

struct ContentView: View {
    @AppStorage("accentChoice") private var accentChoiceRaw: String = AccentChoice.multicolor.rawValue
    @State private var searchText: String = ""
    
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
        TabView {
            Tab("Train", systemImage: "dumbbell") {
                TrainView()
            }

            Tab("Mesocycles", systemImage: "chart.line.uptrend.xyaxis") {
                MesocyclesView()
            }

            Tab("Exercises", systemImage: "books.vertical") {
                ExerciseView()
                    .searchable(text: $searchText)
            }

            Tab("More", systemImage: "gear") {
                MoreView()
            }

            Tab("Chat", systemImage: "bubble.left.and.bubble.right.fill", role: .search) {
                NavigationStack {
                    ChatWindowView()
                }
            }
        }
        .tint(MulticolorAccent.isMulticolor ? MulticolorAccent.color(for: .primary) : selectedAccentColor)
        .glassBackground()
    }
}

#Preview {
    ContentView()
}
