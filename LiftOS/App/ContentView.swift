import SwiftUI

struct ContentView: View {
    @AppStorage("accentChoice") private var accentChoiceRaw: String = AccentChoice.multicolor.rawValue
    
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
            TrainView()
                .tabItem { Label("Train", systemImage: "dumbbell") }

            MesocyclesView()
                .tabItem { Label("Mesocycles", systemImage: "rectangle.grid.1x2") }

            ExercisesView()
                .tabItem { Label("Exercises", systemImage: "books.vertical") }

            MoreView()
                .tabItem { Label("More", systemImage: "ellipsis.circle") }
        }
        .tint(MulticolorAccent.isMulticolor ? MulticolorAccent.color(for: .primary) : selectedAccentColor)
        .glassBackground()
    }
}
