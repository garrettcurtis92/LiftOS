// Builds SessionSummary and derived metrics
import Foundation

struct SummaryBuilder {
    struct Result {
        let summary: SessionSummary
        let perExerciseVolume: [String: Double]
        let perExerciseTopSet: [String: Double]
        let prFlags: [String: (top: Bool, vol: Bool)]
    }

    static func build(title: String, date: Date, sets: [CompletedSet], sessionStart: Date?) -> Result {
        var summary = SessionSummary(title: title, date: date, sets: sets)
        if let start = sessionStart {
            summary.durationSeconds = max(1, Int(date.timeIntervalSince(start)))
        }

        var perExerciseVolume: [String: Double] = [:]
        var perExerciseTopSet: [String: Double] = [:]
        for s in sets {
            guard let w = s.weight, let r = s.reps else { continue }
            perExerciseVolume[s.exerciseName, default: 0] += (w * Double(r))
            perExerciseTopSet[s.exerciseName] = max(perExerciseTopSet[s.exerciseName] ?? 0, w)
        }

        var prFlags: [String: (top: Bool, vol: Bool)] = [:]
        let store = PRStore.shared
        store.load()
        for (name, vol) in perExerciseVolume {
            let top = perExerciseTopSet[name]
            let flags = store.updatePR(exerciseName: name, topSetLoad: top, volume: vol)
            prFlags[name] = (flags.newTopPR, flags.newVolumePR)
        }
        store.save()

        summary.userInfo = [
            "duration": summary.durationSeconds ?? 0,
            "perExerciseVolume": perExerciseVolume,
            "perExerciseTopSet": perExerciseTopSet,
            "prFlags": prFlags.mapValues { ["top": $0.top, "vol": $0.vol] }
        ]

        return .init(summary: summary,
                     perExerciseVolume: perExerciseVolume,
                     perExerciseTopSet: perExerciseTopSet,
                     prFlags: prFlags)
    }
}
