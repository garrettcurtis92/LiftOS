// TrainView.swift
import SwiftUI

struct TrainView: View {
    let mesocycleID: UUID?   // optional so Train tab can do TrainView()

    init(mesocycleID: UUID? = nil) {
        self.mesocycleID = mesocycleID
    }

    @AppStorage("scheduleMode")  private var scheduleMode: ScheduleMode = .fixedWeekdays
    @AppStorage("daysPerWeek")   private var daysPerWeek: Int = 3
    @AppStorage("currentWeek")   private var currentWeek: Int = 1
    @AppStorage("currentDayIx")  private var currentDayIx: Int = 0
    @State private var showSchedulePopover = false

    private func dayLabel(ix: Int) -> String {
        visibleDays(mode: scheduleMode, daysPerWeek: daysPerWeek)[ix]
    }
    private func plannedPresetForSelectedDay(ix: Int) -> String {
        switch ix { case 0: return "Push"; case 1: return "Pull"; case 2: return "Legs"; default: return "Accessory" }
    }
    private var sessionKey: String { "\(currentWeek)-\(currentDayIx)-\(plannedPresetForSelectedDay(ix: currentDayIx))" }

    var body: some View {
        WorkoutSessionView(
            dayLabel: dayLabel(ix: currentDayIx),
            preset: plannedPresetForSelectedDay(ix: currentDayIx),
            mesocycleID: mesocycleID
        )
        .id("\(mesocycleID?.uuidString ?? "none")#\(sessionKey)")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Haptics.tap()
                    showSchedulePopover = true
                } label: {
                    Image(systemName: "calendar")
                        .foregroundStyle(MulticolorAccent.color(for: .calendar))
                }
                .accessibilityLabel("Schedule")
            }
        }
        .navigationTitle("Train") // << matches "Mesocycles"
        .navigationBarTitleDisplayMode(.large)
        .popover(isPresented: $showSchedulePopover, arrowEdge: .top) {
            GlobalSchedulePopover(onClose: { showSchedulePopover = false })
        }
    }
        
}

#Preview{TrainView()}
