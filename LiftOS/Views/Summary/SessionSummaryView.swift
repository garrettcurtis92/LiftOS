import SwiftUI

struct SessionSummaryView: View {
    let summary: SessionSummary

    @AppStorage("weightUnit") private var weightUnit: WeightUnit = .lb
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerSection
                statsSection
                exerciseBreakdownSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 24)
        }
        .navigationTitle("Summary")
        .dsNavigationStyle()
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .firstTextBaseline) {
            Label(summary.title, systemImage: "figure.strengthtraining.traditional")
                .labelStyle(.titleAndIcon)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.primary)

            Spacer()

            if let duration = extractDuration() ?? calculateFallbackDuration() {
                Text(timeString(seconds: duration))
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Duration \(timeString(seconds: duration))")
            }
        }
    }

    // MARK: - Totals (Volume / Sets / Reps)

    private var statsSection: some View {
        let perVol = extractPerExerciseVolume()
        let totalVolume: Double = perVol.values.reduce(0, +)
        let totalSets = summary.sets.count
        let totalReps = summary.sets.compactMap { $0.reps }.reduce(0, +)

        return HStack(spacing: 12) {
            statChip(title: "Volume", value: formatWeight(totalVolume, unit: weightUnit))
            statChip(title: "Sets",   value: "\(totalSets)")
            statChip(title: "Reps",   value: "\(totalReps)")
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Per-exercise list + PR badges

    private var exerciseBreakdownSection: some View {
        let perVol = extractPerExerciseVolume()
        let perTop = extractPerExerciseTopSet()
        let prFlags = extractPRFlags()

        let names = Array(perVol.keys).sorted()

        return VStack(alignment: .leading, spacing: 8) {
            if !names.isEmpty {
                Text("Breakdown")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }

            ForEach(names, id: \.self) { name in
                exerciseRow(
                    name: name,
                    volume: perVol[name] ?? 0,
                    topSet: perTop[name] ?? 0,
                    flags: prFlags[name] ?? [:]
                )
            }
        }
    }

    // MARK: - Helpers (UI)

    private func statChip(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline.monospacedDigit())
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func exerciseRow(name: String, volume: Double, topSet: Double, flags: [String: Bool]) -> some View {
        HStack(spacing: 12) {
            // Name + PR badges
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    if flags["top"] == true {
                        Label("Top PR", systemImage: "rosette")
                            .labelStyle(.iconOnly)
                            .foregroundStyle(.tint)
                            .overlay(Text("Top PR").font(.caption2).foregroundStyle(.secondary).padding(.leading, 18), alignment: .leading)
                    }
                    if flags["vol"] == true {
                        Label("Vol PR", systemImage: "chart.bar")
                            .labelStyle(.iconOnly)
                            .foregroundStyle(.tint)
                            .overlay(Text("Vol PR").font(.caption2).foregroundStyle(.secondary).padding(.leading, 18), alignment: .leading)
                    }
                }
            }

            Spacer()

            // Numbers
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatWeight(volume, unit: weightUnit))
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
                if topSet > 0 {
                    Text("Top \(formatWeight(topSet, unit: weightUnit))")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    // MARK: - Data extraction (from userInfo) + fallbacks

    private func extractDuration() -> Int? {
        summary.userInfo?["duration"] as? Int
    }
    private func extractPerExerciseVolume() -> [String: Double] {
        summary.userInfo?["perExerciseVolume"] as? [String: Double] ?? calculateFallbackData().volume
    }
    private func extractPerExerciseTopSet() -> [String: Double] {
        summary.userInfo?["perExerciseTopSet"] as? [String: Double] ?? calculateFallbackData().topSet
    }
    private func extractPRFlags() -> [String: [String: Bool]] {
        summary.userInfo?["prFlags"] as? [String: [String: Bool]] ?? [:]
    }

    private func calculateFallbackDuration() -> Int? {
        // If you want, you can compute from summary.start/end times if you store them
        nil
    }

    private func calculateFallbackData() -> (volume: [String: Double], topSet: [String: Double]) {
        var volume: [String: Double] = [:]
        var topSet: [String: Double] = [:]

        for set in summary.sets {
            if let w = set.weight, let r = set.reps {
                volume[set.exerciseName, default: 0] += (w * Double(r))
                topSet[set.exerciseName] = max(topSet[set.exerciseName] ?? 0, w)
            }
        }
        return (volume, topSet)
    }

    // MARK: - Formatting

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