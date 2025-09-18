//
//  Exercise.swift
//  LiftOS
//
//  Created by Garrett Curtis on 9/17/25.
//
// Exercise.swift
// SwiftData model for both prefills and custom user-created exercises.

import SwiftData
import Foundation

@Model
final class Exercise {
    enum Source: String, Codable, CaseIterable {
        case prefill   // ships with the app (seeded on first run)
        case custom    // created by the user on-device
    }

    enum MuscleGroup: String, Codable, CaseIterable, Identifiable {
        case chest, back, triceps, biceps, shoulders, quads, glutes, hamstrings, calves, traps, forearms, abs
        var id: String { rawValue.capitalized }
    }

    enum ExerciseType: String, Codable, CaseIterable, Identifiable {
        case machine, barbell, smithMachine, dumbbell, cableFreeMotion, bodyweightOnly, bodyweightLoadable, machineAssistance
        var id: String { rawValue }
    }

    // MARK: - Stored properties
    var name: String
    var muscleGroupRaw: String
    var typeRaw: String
    var sourceRaw: String
    var youtubeVideoID: String?   // optional, for later video playback

    @Relationship(deleteRule: .cascade, inverse: \ExerciseNote.exercise)
    var notes: [ExerciseNote] = []

    // MARK: - Convenience typed accessors
    var muscleGroup: MuscleGroup {
        get { MuscleGroup(rawValue: muscleGroupRaw) ?? .chest }
        set { muscleGroupRaw = newValue.rawValue }
    }
    var type: ExerciseType {
        get { ExerciseType(rawValue: typeRaw) ?? .machine }
        set { typeRaw = newValue.rawValue }
    }
    var source: Source {
        get { Source(rawValue: sourceRaw) ?? .prefill }
        set { sourceRaw = newValue.rawValue }
    }

    // MARK: - Initializer
    init(name: String,
         muscleGroup: MuscleGroup,
         type: ExerciseType,
         source: Source,
         youtubeVideoID: String? = nil) {
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.muscleGroupRaw = muscleGroup.rawValue
        self.typeRaw = type.rawValue
        self.sourceRaw = source.rawValue
        self.youtubeVideoID = youtubeVideoID
    }
}

