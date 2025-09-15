//
//  WeekDayHeader.swift
//  LiftOS
//
//  Created by Garrett Curtis on 9/13/25.
//
import SwiftUI

struct WeekDayHeader: View {
    // Bind into @AppStorage via bridging props
    @Binding var currentWeek: Int       // 1...6 (W1..W5 + Deload as 6)
    @Binding var currentDayIx: Int      // 0-based into `days`
    let days: [String]
    let mode: ScheduleMode
    
    var onSelectDay: ((Int, Int) -> Void)? = nil
    // RIR helper from your existing rules
    private func rir(for week: Int) -> String {
        switch week {
        case 1: return "3 RIR"
        case 2: return "2 RIR"
        case 3: return "1 RIR"
        case 4: return "0–1 RIR"
        case 5: return "PR"
        default: return "Deload"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.md.rawValue) {
            // Top row: Weeks with small RIR labels
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DS.Space.sm.rawValue) {
                    ForEach(1...6, id: \.self) { w in
                        Button {
                            Haptics.tap()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                currentWeek = w
                            }
                        } label: {
                            VStack(spacing: 4) {
                                Text(w == 6 ? "DL" : "\(w)")
                                    .font(.headline)
                                Text(rir(for: w))
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(width: 64, height: 56)
                        }
                        .buttonStyle(.bordered)
                        .tint(w == currentWeek ? .accentColor : .secondary)
                    }
                }
                .padding(.horizontal, DS.Space.lg.rawValue)
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: DS.Space.sm.rawValue), count: min(days.count, 7)),
                                  spacing: DS.Space.sm.rawValue) {
                            ForEach(days.indices, id: \.self) { ix in
                                Button {
                                    Haptics.tap()
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        currentDayIx = ix
                                    }
                                    onSelectDay?(currentWeek, ix)   // ⬅️ notify parent
                                } label: {
                                    Text(days[ix])
                                        .font(TypeScale.body(.semibold))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
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
