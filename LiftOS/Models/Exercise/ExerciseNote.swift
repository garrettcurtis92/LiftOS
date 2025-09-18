//
//  ExerciseNote.swift
//  LiftOS
//
//  Created by Garrett Curtis on 9/17/25.
//
// ExerciseNote.swift
import SwiftData
import Foundation

@Model
final class ExerciseNote {
    var text: String
    var createdAt: Date
    var exercise: Exercise?   // inverse defined on Exercise.notes

    init(text: String, createdAt: Date = .now, exercise: Exercise?) {
        self.text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        self.createdAt = createdAt
        self.exercise = exercise
    }
}
