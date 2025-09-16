// Compact schedule ribbon used at top
import SwiftUI

struct WeekDayRibbon: View {
    @AppStorage("scheduleMode")  private var scheduleMode: ScheduleMode = .fixedWeekdays
    @AppStorage("daysPerWeek")   private var daysPerWeek: Int = 3
    @AppStorage("currentWeek")   private var currentWeek: Int = 1
    @AppStorage("currentDayIx")  private var currentDayIx: Int = 0

    var onTap: () -> Void

    private var dayLabel: String { visibleDays(mode: scheduleMode, daysPerWeek: daysPerWeek)[currentDayIx] }
    private var weekLabel: String { currentWeek == 6 ? "DL" : "W\(currentWeek)" }

    var body: some View {
        HStack(spacing: DS.Space.md.rawValue) {
            HStack(spacing: 6) { Image(systemName: "calendar.badge.clock"); Text(weekLabel).font(TypeScale.subheadline(.semibold)) }
                .padding(.vertical, 6).padding(.horizontal, 10)
                .background(.thinMaterial, in: Capsule()).overlay(Capsule().strokeBorder(Color.white.opacity(0.08)))
            HStack(spacing: 6) { Image(systemName: "bolt.fill"); Text(dayLabel).font(TypeScale.subheadline(.semibold)) }
                .padding(.vertical, 6).padding(.horizontal, 10)
                .background(.thinMaterial, in: Capsule()).overlay(Capsule().strokeBorder(Color.white.opacity(0.08)))
            Spacer()
            Image(systemName: "chevron.down").font(.footnote).foregroundStyle(.secondary)
        }
        .contentShape(Rectangle())
        .onTapGesture { Haptics.tap(); onTap() }
        .padding(.horizontal, DS.Space.lg.rawValue)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
    }
}
