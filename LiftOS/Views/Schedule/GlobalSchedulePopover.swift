// Full schedule popover used across tabs
import SwiftUI

struct GlobalSchedulePopover: View {
    @AppStorage("scheduleMode")  private var scheduleMode: ScheduleMode = .fixedWeekdays
    @AppStorage("daysPerWeek")   private var daysPerWeek: Int = 3
    @AppStorage("currentWeek")   private var currentWeek: Int = 1
    @AppStorage("currentDayIx")  private var currentDayIx: Int = 0
    @AppStorage("totalWeeks")    private var totalWeeks: Int = 5

    @State private var pendingSelection: (week: Int, dayIx: Int)? = nil
    @State private var showWeekSwitchAlert = false

    var onClose: () -> Void

    // Adaptive layout: columns match the configured workouts per week
    private var dayColumns: [GridItem] {
        let count = max(daysPerWeek, 1)
        return Array(repeating: GridItem(.flexible(minimum: 44), spacing: DS.Space.sm.rawValue, alignment: .center), count: count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.md.rawValue) {
            Text("Schedule").font(TypeScale.title()).padding(.horizontal, DS.Space.lg.rawValue).padding(.top, DS.Space.lg.rawValue)

            // Full mesocycle grid: totalWeeks rows x 7 days
            ScrollView {
                VStack(spacing: DS.Space.md.rawValue) {
                    ForEach(1...max(totalWeeks, 1), id: \.self) { week in
                        VStack(alignment: .leading, spacing: DS.Space.xs.rawValue) {
                            HStack {
                                Text("Week \(week == 6 ? "DL" : String(week))")
                                    .font(TypeScale.headline())
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                            // Adaptive grid with the selected number of workout days
                            LazyVGrid(columns: dayColumns, alignment: .center, spacing: DS.Space.sm.rawValue) {
                                let days = visibleDays(mode: scheduleMode, daysPerWeek: daysPerWeek)
                                ForEach(Array(days.enumerated()), id: \.offset) { tup in
                                    let ix = tup.offset
                                    let label = tup.element
                                    Button {
                                        Haptics.tap()
                                        if week == currentWeek && ix == currentDayIx {
                                            onClose()
                                        } else if week == currentWeek {
                                            currentDayIx = ix
                                            onClose()
                                        } else {
                                            pendingSelection = (week, ix)
                                            showWeekSwitchAlert = true
                                        }
                                    } label: {
                                        Text(label)
                                            .font(TypeScale.subheadline(.semibold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.8)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 6)
                                    }
                                    .buttonStyle(.bordered)
                                    .tint(week == currentWeek && ix == currentDayIx ? .accentColor : .secondary)
                                }
                            }
                        }
                        .padding(.horizontal, DS.Space.lg.rawValue)
                    }
                }
                .padding(.top, DS.Space.md.rawValue)
            }

            HStack { Spacer(); PrimaryButton(title: "Done", systemIcon: "checkmark.circle.fill", style: .success) { onClose() } .padding(.horizontal, DS.Space.lg.rawValue).padding(.bottom, DS.Space.lg.rawValue) }
        }
        .alert("Switch to Week \(pendingSelection?.week ?? 1)?", isPresented: $showWeekSwitchAlert) {
            Button("Cancel", role: .cancel) { pendingSelection = nil }
            Button("Switch") { if let p = pendingSelection { currentWeek = p.week; currentDayIx = p.dayIx }; pendingSelection = nil; onClose() }
        } message: { Text("Auto-regulated targets apply only to the current week. You can always change back in Settings.") }
        .presentationDetents([.large])
    }
}
