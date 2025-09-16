import SwiftUI

struct TrainView: View {
    @AppStorage("scheduleMode")  private var scheduleMode: ScheduleMode = .fixedWeekdays
    @AppStorage("daysPerWeek")   private var daysPerWeek: Int = 3
    @AppStorage("currentWeek")   private var currentWeek: Int = 1
    @AppStorage("currentDayIx")  private var currentDayIx: Int = 0

    @State private var showSchedulePopover = false
    // Selection and alert handled inside GlobalSchedulePopover now

    private func dayLabel(ix: Int) -> String { visibleDays(mode: scheduleMode, daysPerWeek: daysPerWeek)[ix] }
    private func plannedPresetForSelectedDay(ix: Int) -> String {
        switch ix { case 0: return "Push"; case 1: return "Pull"; case 2: return "Legs"; default: return "Accessory" }
    }
    private var sessionKey: String { "\(currentWeek)-\(currentDayIx)-\(plannedPresetForSelectedDay(ix: currentDayIx))" }

    var body: some View {
        NavigationStack {
            WorkoutSessionView(dayLabel: dayLabel(ix: currentDayIx), preset: plannedPresetForSelectedDay(ix: currentDayIx))
                .id(sessionKey)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { Haptics.tap(); showSchedulePopover = true } label: { Image(systemName: "calendar") }
                            .accessibilityLabel("Schedule")
                    }
                }
                .popover(isPresented: $showSchedulePopover, arrowEdge: .top) {
                    GlobalSchedulePopover(onClose: { showSchedulePopover = false })
                }
        }
    }
}
