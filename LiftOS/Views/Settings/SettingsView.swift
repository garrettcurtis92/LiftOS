// Settings feature root
import SwiftUI

struct SettingsView: View {
    @AppStorage("weightUnit") private var weightUnit: WeightUnit = .lb
    @AppStorage("currentWeek") private var currentWeek: Int = 1
    @AppStorage("scheduleMode")  private var scheduleMode: ScheduleMode = .fixedWeekdays
    @AppStorage("daysPerWeek")   private var daysPerWeek: Int = 3
    @AppStorage("totalWeeks")    private var totalWeeks: Int = 5
    @AppStorage("currentDayIx")  private var currentDayIx: Int = 0

    var body: some View {
        Form {
            Section("Units") {
                Picker("Weight", selection: $weightUnit) { ForEach(WeightUnit.allCases) { unit in Text(unit.display).tag(unit) } }
                .pickerStyle(.segmented)
            }
            Section("Mesocycle") {
                Picker("Current Week", selection: $currentWeek) {
                    ForEach(1...max(totalWeeks, 1), id: \.self) { w in Text("Week \(w)").tag(w) }
                }
                .pickerStyle(.segmented)
                Stepper("Total Weeks: \(totalWeeks)", value: $totalWeeks, in: 1...12)
                Text("RIR target auto-fills by week.").font(.footnote).foregroundStyle(.secondary)
            }
            Section("Schedule") {
                Picker("Mode", selection: $scheduleMode) { ForEach(ScheduleMode.allCases) { m in Text(m.display).tag(m) } }
                .pickerStyle(.segmented)
                Stepper("Days / Week: \(daysPerWeek)", value: $daysPerWeek, in: 2...6)
                Text(scheduleMode == .fixedWeekdays ? "Shows weekday labels (Mon, Wed, Fri…)." : "Shows ordered days (Day 1, Day 2, Day 3…).")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Settings")
        .onChange(of: totalWeeks) { _, newValue in
            // Clamp currentWeek if totalWeeks decreases below the current selection
            if currentWeek > newValue { currentWeek = newValue }
        }
        .onChange(of: daysPerWeek) { _, newValue in
            // Clamp selected day index into new range
            let maxIx = max(newValue - 1, 0)
            if currentDayIx > maxIx { currentDayIx = maxIx }
        }
    }
}
