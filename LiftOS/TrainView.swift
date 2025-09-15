import SwiftUI

struct TrainView: View {
    // App-wide schedule prefs
    @AppStorage("scheduleMode")  private var scheduleMode: ScheduleMode = .fixedWeekdays
    @AppStorage("daysPerWeek")   private var daysPerWeek: Int = 3
    @AppStorage("currentWeek")   private var currentWeek: Int = 1
    @AppStorage("currentDayIx")  private var currentDayIx: Int = 0

    // UI state
    @State private var showSchedulePopover = false
    @State private var pendingSelection: (week: Int, dayIx: Int)? = nil
    @State private var showWeekSwitchAlert = false

    // MARK: - Helpers
    private func dayLabel(ix: Int) -> String {
        visibleDays(mode: scheduleMode, daysPerWeek: daysPerWeek)[ix]
    }
    private func plannedPresetForSelectedDay(ix: Int) -> String {
        switch ix {
        case 0: return "Push"
        case 1: return "Pull"
        case 2: return "Legs"
        default: return "Accessory"
        }
    }
    // Changes to this value will force-recreate the WorkoutSessionView
    private var sessionKey: String {
        "\(currentWeek)-\(currentDayIx)-\(plannedPresetForSelectedDay(ix: currentDayIx))"
    }

    var body: some View {
        NavigationStack {
            // Directly render the current session
            WorkoutSessionView(
                dayLabel: dayLabel(ix: currentDayIx),
                preset: plannedPresetForSelectedDay(ix: currentDayIx)
            )
            // Recreate view when week/day/preset changes so exercises/title update immediately
            .id(sessionKey)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.tap()
                        showSchedulePopover = true
                    } label: { Image(systemName: "calendar") }
                    .accessibilityLabel("Schedule")
                }
            }
            .popover(isPresented: $showSchedulePopover, arrowEdge: .top) {
                VStack(alignment: .leading, spacing: DS.Space.md.rawValue) {
                    Text("Schedule")
                        .font(TypeScale.title())
                        .padding(.horizontal, DS.Space.lg.rawValue)
                        .padding(.top, DS.Space.lg.rawValue)

                    WeekDayHeader(
                        currentWeek: $currentWeek,
                        currentDayIx: $currentDayIx,
                        days: visibleDays(mode: scheduleMode, daysPerWeek: daysPerWeek),
                        mode: scheduleMode,
                        onSelectDay: { week, dayIx in
                            if week == currentWeek {
                                // Same week → apply and close (view will rebuild via .id)
                                currentDayIx = dayIx
                                showSchedulePopover = false
                            } else {
                                // Different week → confirm switch, then rebuild
                                pendingSelection = (week, dayIx)
                                showWeekSwitchAlert = true
                            }
                        }
                    )

                    HStack {
                        Spacer()
                        PrimaryButton(title: "Done", systemIcon: "checkmark.circle.fill") {
                            showSchedulePopover = false
                        }
                        .padding(.horizontal, DS.Space.lg.rawValue)
                        .padding(.bottom, DS.Space.lg.rawValue)
                    }
                }
                .presentationDetents([.medium])
            }
            .alert("Switch to Week \(pendingSelection?.week ?? 1)?", isPresented: $showWeekSwitchAlert) {
                Button("Cancel", role: .cancel) { pendingSelection = nil }
                Button("Switch") {
                    if let p = pendingSelection {
                        currentWeek = p.week
                        currentDayIx = p.dayIx
                    }
                    pendingSelection = nil
                    showSchedulePopover = false
                    // WorkoutSessionView re-creates via .id(sessionKey)
                }
            } message: {
                Text("Auto-regulated targets apply only to the current week. You can always change back in Settings.")
            }
        }
    }
}
