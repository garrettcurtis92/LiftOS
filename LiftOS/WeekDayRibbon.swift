//
//  WeekDayRibbon.swift
//  LiftOS
//
//  Created by Garrett Curtis on 9/13/25.
//
import SwiftUI

struct WeekDayRibbon: View {
    @AppStorage("scheduleMode")  private var scheduleMode: ScheduleMode = .fixedWeekdays
    @AppStorage("daysPerWeek")   private var daysPerWeek: Int = 3
    @AppStorage("currentWeek")   private var currentWeek: Int = 1
    @AppStorage("currentDayIx")  private var currentDayIx: Int = 0

    var onTap: () -> Void   // open the full calendar popover

    private var dayLabel: String {
        visibleDays(mode: scheduleMode, daysPerWeek: daysPerWeek)[currentDayIx]
    }

    private var weekLabel: String {
        currentWeek == 6 ? "DL" : "W\(currentWeek)"
    }

    var body: some View {
        HStack(spacing: DS.Space.md.rawValue) {
            // Week chip
            HStack(spacing: 6) {
                Image(systemName: "calendar.badge.clock")
                Text(weekLabel)
                    .font(TypeScale.subheadline(.semibold))
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(.thinMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder(Color.white.opacity(0.08)))

            // Day chip
            HStack(spacing: 6) {
                Image(systemName: "bolt.fill")
                Text(dayLabel)
                    .font(TypeScale.subheadline(.semibold))
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(.thinMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder(Color.white.opacity(0.08)))

            Spacer()

            // Chevron to hint it’s interactive
            Image(systemName: "chevron.down")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .contentShape(Rectangle())
        .onTapGesture { Haptics.tap(); onTap() }
        .padding(.horizontal, DS.Space.lg.rawValue)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial) // melts into the top
    }
}
