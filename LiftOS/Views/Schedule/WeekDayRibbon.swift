import SwiftUI

/// Small, tappable ribbon that shows current Week/Day. Used **only** in WorkoutSessionView.
struct WeekDayRibbon: View {
    var onTap: () -> Void

    @AppStorage("currentWeek") private var currentWeek: Int = 1
    @AppStorage("currentDayIx") private var currentDayIx: Int = 0
    @AppStorage("daysPerWeek") private var daysPerWeek: Int = 3

    private var dayLabel: String {
        let weekdays = ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]
        if daysPerWeek <= 7, currentDayIx < weekdays.count {
            return weekdays[currentDayIx]
        } else {
            return "Day \(currentDayIx + 1)"
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                Text("W\(currentWeek)")
                    .monospacedDigit()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.thinMaterial, in: Capsule(style: .continuous))

            HStack(spacing: 6) {
                Image(systemName: "bolt.fill")
                Text(dayLabel)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.thinMaterial, in: Capsule(style: .continuous))

            Spacer()
            Image(systemName: "chevron.down")
                .foregroundStyle(.secondary)
        }
        .font(.footnote.weight(.semibold))
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Color.clear
                .background(.ultraThinMaterial)
                .opacity(0.0001) // keep taps easy without visible background
        )
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }
}
