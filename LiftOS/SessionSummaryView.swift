//
//  SessionSummaryView.swift
//  LiftOS
//
//  Created by Garrett Curtis on 9/13/25.
//
import SwiftUI

struct SessionSummaryView: View {
    let summary: SessionSummary
    @AppStorage("weightUnit") private var weightUnit: WeightUnit = .lb
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header with title and duration
                headerSection
                
                // Overall stats chips
                statsSection
                
                // Per-exercise breakdown with PR badges
                exerciseBreakdownSection
            }
            .padding()
        }
        .navigationTitle("Summary")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack {
            Label(summary.title, systemImage: "figure.strengthtraining.traditional")
                .font(.title2.weight(.semibold))
            Spacer()
            if let duration = extractDuration() {
                Text(timeString(seconds: duration))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // MARK: - Stats Section
    
    private var statsSection: some View {
        let perVol = extractPerExerciseVolume()
        let totalVolume = perVol.values.reduce(0, +)
        let totalSets = summary.sets.count
        let totalReps = summary.sets.compactMap { $0.reps }.reduce(0, +)
        
        // Fallback: if userInfo is empty, calculate volume from sets directly
        let fallbackVolume = summary.sets.reduce(0) { $0 + $1.volume }
        let displayVolume = totalVolume > 0 ? totalVolume : fallbackVolume
        
        return HStack(spacing: 16) {
            statChip(title: "Volume", value: formatWeight(displayVolume, unit: weightUnit))
            statChip(title: "Sets", value: "\(totalSets)")
            statChip(title: "Reps", value: "\(totalReps)")
        }
    }
    
    // MARK: - Exercise Breakdown Section
    
    private var exerciseBreakdownSection: some View {
        let perVol = extractPerExerciseVolume()
        let perTop = extractPerExerciseTopSet()
        let prFlags = extractPRFlags()
        
        // Fallback: if userInfo data is empty, calculate from sets directly
        let fallbackData = calculateFallbackData()
        let exerciseNames = perVol.isEmpty ? Array(fallbackData.volume.keys).sorted() : Array(perVol.keys).sorted()
        
        return VStack(alignment: .leading, spacing: 8) {
            Text("Exercise Breakdown")
                .font(.headline)
                .padding(.bottom, 4)
            
            ForEach(exerciseNames, id: \.self) { name in
                exerciseRow(
                    name: name,
                    volume: perVol[name] ?? fallbackData.volume[name] ?? 0,
                    topSet: perTop[name] ?? fallbackData.topSet[name] ?? 0,
                    flags: prFlags[name] ?? [:]
                )
            }
        }
    }
    
    private func calculateFallbackData() -> (volume: [String: Double], topSet: [String: Double]) {
        var volume: [String: Double] = [:]
        var topSet: [String: Double] = [:]
        
        for set in summary.sets {
            volume[set.exerciseName, default: 0] += set.volume
            if let weight = set.weight {
                topSet[set.exerciseName] = max(topSet[set.exerciseName] ?? 0, weight)
            }
        }
        
        return (volume, topSet)
    }
    
    // MARK: - Helper Views
    
    private func statChip(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.footnote).foregroundStyle(.secondary)
            Text(value).font(.headline).monospacedDigit()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    
    private func exerciseRow(name: String, volume: Double, topSet: Double, flags: [String: Bool]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(name)
                    .font(.subheadline.weight(.medium))
                Spacer()
                
                // PR Badges
                HStack(spacing: 6) {
                    if flags["top"] == true {
                        Label("Top PR", systemImage: "rosette")
                            .font(.caption)
                            .foregroundStyle(.tint)
                            .labelStyle(.iconOnly)
                    }
                    if flags["vol"] == true {
                        Label("Vol PR", systemImage: "chart.bar")
                            .font(.caption)
                            .foregroundStyle(.tint)
                            .labelStyle(.iconOnly)
                    }
                }
                
                Text(formatWeight(volume, unit: weightUnit))
                    .font(.subheadline)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            
            // Top set info
            if topSet > 0 {
                Text("Top Set: \(formatWeight(topSet, unit: weightUnit))")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6))
    }
    
    // MARK: - Data Extraction Helpers
    
    private func extractDuration() -> Int? {
        summary.userInfo?["duration"] as? Int
    }
    
    private func extractPerExerciseVolume() -> [String: Double] {
        summary.userInfo?["perExerciseVolume"] as? [String: Double] ?? [:]
    }
    
    private func extractPerExerciseTopSet() -> [String: Double] {
        summary.userInfo?["perExerciseTopSet"] as? [String: Double] ?? [:]
    }
    
    private func extractPRFlags() -> [String: [String: Bool]] {
        summary.userInfo?["prFlags"] as? [String: [String: Bool]] ?? [:]
    }
    
    // MARK: - Formatting Helpers
    
    private func timeString(seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%dm %02ds", m, s)
    }
    
    private func formatWeight(_ x: Double, unit: WeightUnit) -> String {
        let rounded = (x.rounded() == x) ? "\(Int(x))" : String(format: "%.1f", x)
        return unit == .kg ? "\(rounded) kg" : "\(rounded) lb"
    }
}
