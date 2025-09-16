import SwiftUI

struct ContentView: View {
    @State private var showSchedulePopover = false

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
        .safeAreaInset(edge: .top) {
            WeekDayRibbon {
                showSchedulePopover = true
            }
        }
        .popover(isPresented: $showSchedulePopover, arrowEdge: .top) {
            GlobalSchedulePopover(onClose: { showSchedulePopover = false })
        }
    }
}
