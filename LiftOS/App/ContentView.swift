import SwiftUI

struct ContentView: View {
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
        .tint(.primary)
        .glassBackground()
    }
}
