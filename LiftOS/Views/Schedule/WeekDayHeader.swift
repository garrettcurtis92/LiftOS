import SwiftUI

struct WeekDayHeader: View {
    @Binding var currentWeek: Int
    @Binding var currentDayIx: Int
    let days: [String]
    let mode: ScheduleMode
    var onSelectDay: ((Int, Int) -> Void)? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.md.rawValue) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DS.Space.sm.rawValue) {
                    ForEach(1...6, id: \.self) { w in
                        Button { Haptics.tap(); withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { currentWeek = w } } label: {
                            VStack(spacing: 4) {
                                Text(w == 6 ? "DL" : "W\(w)")
                                    .font(.headline)
                            }
                                .frame(width: 64, height: 56)
                        }
                        .buttonStyle(.bordered)
                        .tint(w == currentWeek ? .accentColor : .secondary)
                    }
                }
                .padding(.horizontal, DS.Space.lg.rawValue)
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: DS.Space.sm.rawValue), count: min(days.count, 7)), spacing: DS.Space.sm.rawValue) {
                ForEach(days.indices, id: \.self) { ix in
                    Button { Haptics.tap(); withAnimation(.easeInOut(duration: 0.2)) { currentDayIx = ix }; onSelectDay?(currentWeek, ix) } label: {
                        Text(days[ix]).font(TypeScale.body(.semibold)).frame(maxWidth: .infinity).padding(.vertical, 10)
                    }
                    .buttonStyle(.bordered)
                    .tint(ix == currentDayIx ? .accentColor : .secondary)
                }
            }
            .padding(.horizontal, DS.Space.lg.rawValue)
        }
        .padding(.top, DS.Space.md.rawValue)
    }
}
