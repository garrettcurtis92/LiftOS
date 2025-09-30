import Foundation
import SwiftData

@Model
final class MesoExerciseLog: Identifiable {
    @Attribute(.unique) var id: UUID
    var mesocycleID: UUID
    var week: Int
    var dayIx: Int
    var exerciseName: String
    var date: Date
    var setsData: Data

    init(mesocycleID: UUID, week: Int, dayIx: Int, exerciseName: String, date: Date, setsData: Data) {
        self.id = UUID()
        self.mesocycleID = mesocycleID
        self.week = week
        self.dayIx = dayIx
        self.exerciseName = exerciseName
        self.date = date
        self.setsData = setsData
    }
}
