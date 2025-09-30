import Foundation
import SwiftData
import SwiftUI

@Model
final class WorkoutLogEntry {
    @Attribute(.unique) var id: UUID
    var mesocycleID: UUID
    var week: Int
    var dayIx: Int
    var exerciseName: String
    var exerciseKey: String
    var setIndex: Int
    var weight: Double?
    var reps: Int?
    var done: Bool
    var createdAt: Date
    var updatedAt: Date
    var unitRaw: String

    var unit: WeightUnit {
        get { WeightUnit(rawValue: unitRaw) ?? .lb }
        set { unitRaw = newValue.rawValue }
    }

    init(mesocycleID: UUID, week: Int, dayIx: Int, exerciseName: String, exerciseKey: String, setIndex: Int, weight: Double?, reps: Int?, done: Bool, unit: WeightUnit) {
        self.id = UUID()
        self.mesocycleID = mesocycleID
        self.week = week
        self.dayIx = dayIx
        self.exerciseName = exerciseName
        self.exerciseKey = exerciseKey
        self.setIndex = setIndex
        self.weight = weight
        self.reps = reps
        self.done = done
        self.createdAt = Date()
        self.updatedAt = Date()
        self.unitRaw = unit.rawValue
    }
}
