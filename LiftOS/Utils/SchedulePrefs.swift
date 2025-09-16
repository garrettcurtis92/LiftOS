import SwiftUI

enum ScheduleMode: String, CaseIterable, Identifiable { case fixedWeekdays, flexibleOrder; var id: String { rawValue }; var display: String { self == .fixedWeekdays ? "Weekdays" : "Day Order" } }
struct SchedulePrefs {
	@AppStorage("scheduleMode") var mode: ScheduleMode = .fixedWeekdays
	@AppStorage("daysPerWeek") var daysPerWeek: Int = 3
	@AppStorage("currentWeek") var currentWeek: Int = 1
	@AppStorage("currentDayIx") var currentDayIx: Int = 0
	// Total number of weeks in the mesocycle (used for full-grid schedule views)
	@AppStorage("totalWeeks") var totalWeeks: Int = 5
}

enum WeekdayShort: String, CaseIterable { case Mon, Tue, Wed, Thu, Fri, Sat, Sun }
func visibleDays(mode: ScheduleMode, daysPerWeek: Int) -> [String] { switch mode { case .fixedWeekdays: return Array(WeekdayShort.allCases.prefix(daysPerWeek)).map { $0.rawValue }; case .flexibleOrder: return (1...daysPerWeek).map { "Day \($0)" } } }
