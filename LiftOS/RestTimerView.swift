//
//  RestTimerView.swift
//  LiftOS
//
//  Created by Garrett Curtis on 9/13/25.
//
import SwiftUI
import Combine

struct RestTimerView: View {
    @Environment(\.dismiss) private var dismiss
    let seconds: Int
    var onDone: () -> Void

    @State private var remaining: Int = 0
    @State private var timerCancellable: AnyCancellable?

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black.opacity(0.6), Color.black.opacity(0.9)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Text("Rest")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.white)

                Text(timeString(remaining))
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)

                PrimaryButton(title: "Skip", systemIcon: "forward.fill") {
                    stopTimer()
                    Haptics.warning()
                    dismiss()
                }
                .tint(.white)
            }
            .padding()
        }
        .onAppear {
            remaining = seconds
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }

    private func startTimer() {
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                remaining -= 1
                if remaining <= 0 {
                    Haptics.success()
                    stopTimer()
                    onDone()
                    dismiss()
                }
            }
    }

    private func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    private func timeString(_ s: Int) -> String {
        let m = max(s, 0) / 60
        let ss = max(s, 0) % 60
        return String(format: "%d:%02d", m, ss)
    }
}
