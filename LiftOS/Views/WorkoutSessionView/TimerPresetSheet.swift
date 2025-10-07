//
//  TimerPresetSheet.swift
//  LiftOS
//

import SwiftUI

struct TimerPresetSheet: View {
    let presets: [Int]
    let currentTimer: Int
    let onSelect: (Int) -> Void
    let onStop: () -> Void
    let onDismiss: () -> Void
    
    @AppStorage("restTimerDuration") private var restTimerDuration: Int = 90
    @Environment(\.dismiss) private var dismiss
    
    private func formatTime(_ seconds: Int) -> String {
        if seconds == 0 {
            return "No Timer"
        } else if seconds >= 60 {
            let minutes = seconds / 60
            let remainingSeconds = seconds % 60
            if remainingSeconds == 0 {
                return "\(minutes)m"
            } else {
                return "\(minutes)m \(remainingSeconds)s"
            }
        } else {
            return "\(seconds)s"
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: FitnessDS.Space.xl.rawValue) {
                // Title
                VStack(spacing: FitnessDS.Space.sm.rawValue) {
                    Text("Rest Timer")
                        .font(FitnessDS.Typography.headlineLarge)
                        .fontWeight(.semibold)
                    
                    if currentTimer > 0 {
                        Text("Timer running: \(formatTime(currentTimer))")
                            .font(FitnessDS.Typography.bodyMedium)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Select a preset or start a custom timer")
                            .font(FitnessDS.Typography.bodyMedium)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, FitnessDS.Space.lg.rawValue)
                
                // Preset buttons in a grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: FitnessDS.Space.md.rawValue), count: 2), spacing: FitnessDS.Space.md.rawValue) {
                    ForEach(presets, id: \.self) { seconds in
                        presetButton(for: seconds)
                    }
                }
                .padding(.horizontal, FitnessDS.Space.lg.rawValue)
                
                // Stop button (if timer is running)
                if currentTimer > 0 {
                    Button {
                        Haptics.tap()
                        onStop()
                        dismiss()
                    } label: {
                        HStack(spacing: FitnessDS.Space.sm.rawValue) {
                            Image(systemName: "stop.fill")
                            Text("Stop Timer")
                        }
                        .font(FitnessDS.Typography.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(FitnessDS.Materials.surface, in: Capsule())
                        .overlay(
                            Capsule()
                                .stroke(.red.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, FitnessDS.Space.lg.rawValue)
                    .accessibilityLabel("Stop current timer")
                }
                
                Spacer()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDismiss()
                        dismiss()
                    }
                    .foregroundStyle(.tint)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
    
    // MARK: - Preset Button
    
    @ViewBuilder
    private func presetButton(for seconds: Int) -> some View {
        VStack(spacing: FitnessDS.Space.sm.rawValue) {
            HStack {
                Text(formatTime(seconds))
                    .font(FitnessDS.Typography.headlineMedium)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Star to indicate and set default
                Button {
                    Haptics.tap()
                    restTimerDuration = seconds
                } label: {
                    Image(systemName: restTimerDuration == seconds ? "star.fill" : "star")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(restTimerDuration == seconds ? .yellow : .secondary.opacity(0.5))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
            }
            
            HStack {
                if seconds == 0 {
                    Text(restTimerDuration == seconds ? "Auto-Start Default" : "No Auto-Timer")
                        .font(FitnessDS.Typography.captionMedium)
                        .foregroundStyle(.secondary)
                } else {
                    Text(restTimerDuration == seconds ? "Auto-Start Default" : "Start Timer")
                        .font(FitnessDS.Typography.captionMedium)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
        }
        .foregroundStyle(.tint)
        .frame(maxWidth: .infinity, minHeight: 80)
        .padding(.horizontal, FitnessDS.Space.md.rawValue)
        .background(FitnessDS.Materials.card, in: RoundedRectangle(cornerRadius: FitnessDS.Corners.card))
        .overlay(
            RoundedRectangle(cornerRadius: FitnessDS.Corners.card)
                .stroke(restTimerDuration == seconds ? Color.accentColor.opacity(0.6) : Color.accentColor.opacity(0.3), lineWidth: restTimerDuration == seconds ? 2 : 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: FitnessDS.Corners.card))
        .onTapGesture {
            Haptics.tap()
            onSelect(seconds)
            dismiss()
        }
        .accessibilityLabel(seconds == 0 ? "No timer" : "Start \(formatTime(seconds)) timer")
        .accessibilityHint(restTimerDuration == seconds ? "This is your auto-start default" : "Tap star to set as auto-start default")
    }
}

// MARK: - Preview

#Preview {
    TimerPresetSheet(
        presets: [30, 60, 90, 120],
        currentTimer: 0,
        onSelect: { seconds in
            print("Selected \(seconds) seconds")
        },
        onStop: {
            print("Stop timer")
        },
        onDismiss: {
            print("Dismiss")
        }
    )
}