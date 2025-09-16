// Settings feature root
import SwiftUI

struct SettingsView: View {
    @AppStorage("weightUnit") private var weightUnit: WeightUnit = .lb
    @AppStorage("currentWeek") private var currentWeek: Int = 1
    @AppStorage("scheduleMode")  private var scheduleMode: ScheduleMode = .fixedWeekdays
    @AppStorage("daysPerWeek")   private var daysPerWeek: Int = 3

    var body: some View {
        Form {
            Section("Units") {
                Picker("Weight", selection: $weightUnit) { ForEach(WeightUnit.allCases) { unit in Text(unit.display).tag(unit) } }
                .pickerStyle(.segmented)
            }
            Section("Mesocycle") {
                Picker("Current Week", selection: $currentWeek) { ForEach(1...6, id: \.self) { w in Text("Week \(w)").tag(w) } }
                .pickerStyle(.segmented)
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
    }
}
