// Compact schedule ribbon used at top
import SwiftUI

struct WeekDayRibbon: View {
    @Environment(\.colorScheme) private var scheme
    @AppStorage("scheduleMode")  private var scheduleMode: ScheduleMode = .fixedWeekdays
    @AppStorage("daysPerWeek")   private var daysPerWeek: Int = 3
    @AppStorage("currentWeek")   private var currentWeek: Int = 1
    @AppStorage("currentDayIx")  private var currentDayIx: Int = 0

    var onTap: () -> Void

    private var dayLabel: String { visibleDays(mode: scheduleMode, daysPerWeek: daysPerWeek)[currentDayIx] }
    private var weekLabel: String { currentWeek == 6 ? "DL" : "W\(currentWeek)" }

    var body: some View {
        HStack(spacing: DS.Space.md.rawValue) {
            HStack(spacing: 6) {
                Image(systemName: "calendar.badge.clock").imageScale(.medium)
                Text(weekLabel).font(TypeScale.subheadline(.semibold))
            }
            .foregroundStyle(.primary)
            .padding(.vertical, 6).padding(.horizontal, 10)
            .background(.regularMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder((scheme == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.15)), lineWidth: 1))
            .shadow(color: Color.black.opacity(scheme == .dark ? 0.18 : 0.06), radius: 5, y: 2)

            HStack(spacing: 6) {
                Image(systemName: "bolt.fill").imageScale(.medium)
                Text(dayLabel).font(TypeScale.subheadline(.semibold))
            }
            .foregroundStyle(.primary)
            .padding(.vertical, 6).padding(.horizontal, 10)
            .background(.regularMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder((scheme == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.15)), lineWidth: 1))
            .shadow(color: Color.black.opacity(scheme == .dark ? 0.18 : 0.06), radius: 5, y: 2)
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
