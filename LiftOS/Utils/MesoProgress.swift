import Foundation
import SwiftData

struct MesoProgress {
    static func nextPosition(for mesocycleID: UUID, in context: ModelContext, daysPerWeek: Int, weekCount: Int) -> (week: Int, dayIx: Int)? {
        let totalW = max(weekCount, 1)
        let dPerW = max(daysPerWeek, 1)
        for w in 1...totalW {
            let desc = FetchDescriptor<MesoCompletion>(predicate: #Predicate { $0.week == w && $0.mesocycleID == mesocycleID })
            let items = (try? context.fetch(desc)) ?? []
            let done = Set(items.map { $0.dayIx })
            for i in 0..<dPerW {
                if !done.contains(i) { return (w, i) }
            }
        }
        return nil
    }
}
