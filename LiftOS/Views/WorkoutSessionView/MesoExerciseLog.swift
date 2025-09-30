import SwiftData
import Foundation

@Model
final class ExerciseSetLog {
  @Attribute(.unique) var id: String = UUID().uuidString
  var mesocycle: Int
  var week: Int
  var day: Int
  var exerciseName: String
  var setNumber: Int
  var repetitions: Int
  var weight: Double

  init(mesocycle: Int, week: Int, day: Int, exerciseName: String, setNumber: Int, repetitions: Int, weight: Double) {
    self.mesocycle = mesocycle
    self.week = week
    self.day = day
    self.exerciseName = exerciseName
    self.setNumber = setNumber
    self.repetitions = repetitions
    self.weight = weight
  }
}
