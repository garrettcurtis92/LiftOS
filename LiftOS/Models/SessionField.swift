// Shared focus field for Workout entry
import Foundation

enum SessionField: Hashable {
    case weight(UUID, Int) // (exerciseID, setIndex)
    case reps(UUID, Int)
}
