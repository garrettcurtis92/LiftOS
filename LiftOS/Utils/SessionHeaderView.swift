import SwiftUI

struct SessionHeaderView: View {
    let dayLabel: String
    let currentWeek: Int
    let currentDayIndex: Int
    @Binding var restTimerEnabled: Bool
    @Binding var showRestTimer: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(dayLabel)
                    .font(.title3.weight(.semibold))
                    .accessibilityAddTraits(.isHeader)
                Text("Week \(currentWeek), Day \(currentDayIndex + 1)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                restTimerEnabled.toggle()
                #if canImport(UIKit)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                #endif
                if !restTimerEnabled { showRestTimer = false }
            } label: {
                Image(systemName: restTimerEnabled ? "timer" : "timer.slash")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .padding(10)
                    .background(Circle().fill(.regularMaterial))
                    .overlay(
                        Circle().strokeBorder(Color.primary.opacity(restTimerEnabled ? 0.12 : 0.28), lineWidth: 1)
                    )
            }
            .accessibilityLabel(restTimerEnabled ? "Disable rest timer" : "Enable rest timer")
            .accessibilityValue(restTimerEnabled ? "On" : "Off")
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

#Preview {
    SessionHeaderView(dayLabel: "Monday", currentWeek: 1, currentDayIndex: 0, restTimerEnabled: .constant(true), showRestTimer: .constant(false))
}
