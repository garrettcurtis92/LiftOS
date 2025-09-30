import SwiftUI

struct MesoCompletionCongratsView: View {
    let mesocycleName: String
    let onDone: () -> Void
    @State private var animate = false
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Image(systemName: "rosette")
                    .font(.system(size: 56, weight: .bold))
                    .foregroundStyle(.green)
                    .scaleEffect(animate ? 1.0 : 0.6)
                    .rotationEffect(.degrees(animate ? 0 : -12))
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: animate)
                // Subtle sparkles
                Group {
                    Image(systemName: "sparkles").foregroundStyle(.yellow).opacity(animate ? 1 : 0).offset(x: -44, y: -28)
                    Image(systemName: "sparkles").foregroundStyle(.orange).opacity(animate ? 0.95 : 0).offset(x: 42, y: -22)
                    Image(systemName: "sparkles").foregroundStyle(.mint).opacity(animate ? 0.9 : 0).offset(x: 0, y: -52)
                }
                .scaleEffect(animate ? 1.0 : 0.8)
                .animation(.easeOut(duration: 0.6).delay(0.15), value: animate)
            }
            Text("Congratulations!")
                .font(.largeTitle.weight(.bold))
            Text("You finished \(mesocycleName). Great work.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer()
            PrimaryButton(title: "Done", systemIcon: "checkmark.circle.fill", style: .success, action: onDone)
        }
        .padding()
        .presentationDetents([.medium, .large])
        .onAppear {
            #if canImport(UIKit)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            #endif
            withAnimation { animate = true }
        }
    }
}
