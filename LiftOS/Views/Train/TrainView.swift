import SwiftUI

struct TrainView: View {
    @AppStorage("scheduleMode")  private var scheduleMode: ScheduleMode = .fixedWeekdays
    @AppStorage("daysPerWeek")   private var daysPerWeek: Int = 3
    @AppStorage("currentWeek")   private var currentWeek: Int = 1
    @AppStorage("currentDayIx")  private var currentDayIx: Int = 0

    @State private var showSchedulePopover = false
    @State private var pendingSelection: (week: Int, dayIx: Int)? = nil
    @State private var showWeekSwitchAlert = false

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
                    VStack(alignment: .leading, spacing: DS.Space.md.rawValue) {
                        Text("Schedule").font(TypeScale.title()).padding(.horizontal, DS.Space.lg.rawValue).padding(.top, DS.Space.lg.rawValue)
                        WeekDayHeader(
                            currentWeek: $currentWeek,
                            currentDayIx: $currentDayIx,
                            days: visibleDays(mode: scheduleMode, daysPerWeek: daysPerWeek),
                            mode: scheduleMode,
                            onSelectDay: { week, dayIx in
                                if week == currentWeek { currentDayIx = dayIx; showSchedulePopover = false }
                                else { pendingSelection = (week, dayIx); showWeekSwitchAlert = true }
                            }
                        )
                        HStack { Spacer(); PrimaryButton(title: "Done", systemIcon: "checkmark.circle.fill") { showSchedulePopover = false } .padding(.horizontal, DS.Space.lg.rawValue).padding(.bottom, DS.Space.lg.rawValue) }
                    }
                    .presentationDetents([.medium])
                }
                .alert("Switch to Week \(pendingSelection?.week ?? 1)?", isPresented: $showWeekSwitchAlert) {
                    Button("Cancel", role: .cancel) { pendingSelection = nil }
                    Button("Switch") {
                        if let p = pendingSelection { currentWeek = p.week; currentDayIx = p.dayIx }
                        pendingSelection = nil
                        showSchedulePopover = false
                    }
                } message: { Text("Auto-regulated targets apply only to the current week. You can always change back in Settings.") }
        }
    }
}
