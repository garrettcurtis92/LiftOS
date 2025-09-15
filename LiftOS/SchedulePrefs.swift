//
//  SchedulePrefs.swift
//  LiftOS
//
//  Created by Garrett Curtis on 9/13/25.
//
import SwiftUI

enum ScheduleMode: String, CaseIterable, Identifiable {
    case fixedWeekdays    // Mon/Wed/Fri...
    case flexibleOrder    // Day 1/2/3...
    var id: String { rawValue }

    var display: String {
        switch self {
        case .fixedWeekdays: return "Weekdays"
        case .flexibleOrder: return "Day Order"
        }
    }
}

struct SchedulePrefs {
    @AppStorage("scheduleMode") var mode: ScheduleMode = .fixedWeekdays
    @AppStorage("daysPerWeek")  var daysPerWeek: Int = 3       // 2–6 typical
    @AppStorage("currentWeek")  var currentWeek: Int = 1       // 1..6
    @AppStorage("currentDayIx") var currentDayIx: Int = 0      // 0-based
}

enum WeekdayShort: String, CaseIterable {
    case Mon, Tue, Wed, Thu, Fri, Sat, Sun
}

/// Build the visible day titles based on prefs
func visibleDays(mode: ScheduleMode, daysPerWeek: Int) -> [String] {
    switch mode {
    case .fixedWeekdays:
        // take first N from Mon..Sun
        return Array(WeekdayShort.allCases.prefix(daysPerWeek)).map { $0.rawValue }
    case .flexibleOrder:
        return (1...daysPerWeek).map { "Day \($0)" }
    }
}
