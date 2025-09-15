//
//  GlobalSchedulePopover.swift
//  LiftOS
//
//  Created by Garrett Curtis on 9/13/25.
//
import SwiftUI

struct GlobalSchedulePopover: View {
    @AppStorage("scheduleMode")  private var scheduleMode: ScheduleMode = .fixedWeekdays
    @AppStorage("daysPerWeek")   private var daysPerWeek: Int = 3
    @AppStorage("currentWeek")   private var currentWeek: Int = 1
    @AppStorage("currentDayIx")  private var currentDayIx: Int = 0

    @State private var pendingSelection: (week: Int, dayIx: Int)? = nil
    @State private var showWeekSwitchAlert = false

    var onClose: () -> Void

    var body: some View {
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
                        onClose()
                        // We don’t navigate here; TrainView keeps the Start button,
                        // but you can navigate directly if you want via NotificationCenter/event bus later.
                    } else {
                        pendingSelection = (week, dayIx)
                        showWeekSwitchAlert = true
                    }
                }
            )

            HStack {
                Spacer()
                PrimaryButton(title: "Done", systemIcon: "checkmark.circle.fill") {
                    onClose()
                }
                .padding(.horizontal, DS.Space.lg.rawValue)
                .padding(.bottom, DS.Space.lg.rawValue)
            }
        }
        .alert("Switch to Week \(pendingSelection?.week ?? 1)?", isPresented: $showWeekSwitchAlert) {
            Button("Cancel", role: .cancel) { pendingSelection = nil }
            Button("Switch") {
                if let p = pendingSelection {
                    currentWeek = p.week
                    currentDayIx = p.dayIx
                }
                pendingSelection = nil
                onClose()
            }
        } message: {
            Text("Auto-regulated targets apply only to the current week. You can always change back in Settings.")
        }
        .presentationDetents([.medium])
    }
}
