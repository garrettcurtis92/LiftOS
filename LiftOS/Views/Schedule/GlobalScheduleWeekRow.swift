import SwiftUI

struct WeekRow: View {
    let week: Int
    let days: [String]
    let dayColumns: [GridItem]
    let doneDays: Set<Int>
    let selectedWeek: Int
    let selectedDayIx: Int
    let selectionNS: Namespace.ID
    let colorForDay: (Int, Int, Set<Int>) -> Color
    let strokeColorForDay: (Int, Int, Set<Int>) -> Color
    let textColorForDay: (Int, Int, Set<Int>) -> Color
    let onSelect: (Int, Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.xs.rawValue) {
            HStack {
                Text("Week \(week == 6 ? "DL" : String(week))")
                    .font(TypeScale.headline())
                    .foregroundStyle(.secondary)
                Spacer()
            }
            LazyVGrid(columns: dayColumns, alignment: .center, spacing: DS.Space.sm.rawValue) {
                ForEach(days.indices, id: \.self) { ix in
                    let label = days[ix]
                    let isSelected = (selectedWeek == week) && (selectedDayIx == ix)
                    let fill = colorForDay(ix, week, doneDays)
                    let stroke = strokeColorForDay(ix, week, doneDays)
                    let fg = textColorForDay(ix, week, doneDays)

                    Button { onSelect(week, ix) } label: {
                        DayButtonLabel(
                            label: label,
                            isSelected: isSelected,
                            fill: fill,
                            stroke: stroke,
                            foreground: fg,
                            selectionNS: selectionNS
                        )
                    }
                }
            }
        }
    }
}

