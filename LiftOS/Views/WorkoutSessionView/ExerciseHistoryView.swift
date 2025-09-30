import SwiftUI
import SwiftData

struct ExerciseHistoryView: View {
    let mesocycleID: UUID
    let week: Int
    let dayIx: Int
    let exerciseName: String
    let youtubeVideoID: String?

    @Environment(\.modelContext) private var modelContext

    @State private var entries: [WorkoutLogEntry] = []

    var body: some View {
        List {
            if let youtubeVideoID, !youtubeVideoID.isEmpty {
                Section("Technique") {
                    VideoPlaceholderView(youtubeID: youtubeVideoID)
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }

            Section("History") {
                if entries.isEmpty {
                    ContentUnavailableView("No history yet", systemImage: "clock", description: Text("Log some sets to see them here."))
                } else {
                    ForEach(entries.sorted(by: { $0.setIndex < $1.setIndex })) { e in
                        HStack {
                            Text("Set \(e.setIndex)")
                            Spacer()
                            Text(formatEntry(e))
                                .font(.callout.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle(exerciseName)
        .navigationBarTitleDisplayMode(.inline)
        .task { await reload() }
    }

    private func reload() async {
        let d = FetchDescriptor<WorkoutLogEntry>(
            predicate: #Predicate { $0.mesocycleID == mesocycleID && $0.week == week && $0.dayIx == dayIx && $0.exerciseName == exerciseName },
            sortBy: [SortDescriptor(\.setIndex)]
        )
        let fetched = (try? modelContext.fetch(d)) ?? []
        entries = fetched
    }

    private func formatEntry(_ e: WorkoutLogEntry) -> String {
        switch (e.weight, e.reps, e.done) {
        case let (w?, r?, true): return "\(formatWeight(w)) × \(r) (done)"
        case let (w?, r?, false): return "\(formatWeight(w)) × \(r)"
        case (nil, nil, true): return "Skipped"
        case let (w?, nil, _): return formatWeight(w)
        case let (nil, r?, _): return "\(r) reps"
        default: return "Not set"
        }
    }

    private func formatWeight(_ w: Double) -> String {
        // Unit-agnostic; the caller can adapt later or pass unit in.
        let rounded = (w.rounded() == w) ? "\(Int(w))" : String(format: "%.1f", w)
        return "\(rounded)"
    }
}

// Placeholder for future embedded video (e.g., YouTube player or AVPlayer-based local clip)
struct VideoPlaceholderView: View {
    let youtubeID: String
    var body: some View {
        ZStack {
            Rectangle().fill(.secondary.opacity(0.15))
            VStack(spacing: 8) {
                Image(systemName: "play.rectangle.fill").font(.system(size: 36)).foregroundStyle(.secondary)
                Text("Technique video")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
