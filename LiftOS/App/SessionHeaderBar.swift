import SwiftUI

struct SessionHeaderBar: View {
    let week: Int
    let dayLabel: String
    let sessionProgress: Double // 0.0...1.0
    @Binding var showRestTimer: Bool
    var onPickRestDuration: ((Int) -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 12) {
            Text("Week \(week) · Day \(dayLabel)")
                .font(.headline)
                .dynamicTypeSize(.large ... .xxLarge)
                .numericTextTransitionIfAvailable()
            
            Spacer()
            
            Menu {
                Button("30s") { Haptics.tap(); onPickRestDuration?(30); showRestTimer = true }
                Button("1:00") { Haptics.tap(); onPickRestDuration?(60); showRestTimer = true }
                Button("1:30") { Haptics.tap(); onPickRestDuration?(90); showRestTimer = true }
                Button("2:00") { Haptics.tap(); onPickRestDuration?(120); showRestTimer = true }
            } label: {
                Label("Rest", systemImage: "timer")
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.thinMaterial)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .overlay(Divider(), alignment: .bottom)
    }
}

