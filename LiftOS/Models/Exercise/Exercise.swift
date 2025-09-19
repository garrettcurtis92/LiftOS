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
    // STORED raw strings for predicates
    var name: String
    var sourceRaw: String
    var muscleGroupRaw: String
    var typeRaw: String
    var loadBasisRaw: String? // optional

    // Optional metadata
    var youtubeVideoID: String?   // optional, for later video playback

    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \ExerciseNote.exercise)
    var notes: [ExerciseNote] = []

    // Enums
    enum Source: String, Codable, CaseIterable { case prefill, custom }

    enum MuscleGroup: String, Codable, CaseIterable {
        case chest, back, triceps, biceps, shoulders, quads, glutes, hamstrings, calves, traps, forearms, abs
    }

    enum ExerciseType: String, Codable, CaseIterable {
        case machine, barbell, smithMachine, dumbbell, cable, bodyweightOnly, bodyweightLoadable, machineAssistance
    }

    enum LoadBasis: String, Codable, CaseIterable {
        case bodyweightOnly, bodyweightPlusExternal, externalOnly
    }

    // COMPUTED accessors (read/write the raws)
    var source: Source {
        get { Source(rawValue: sourceRaw) ?? .prefill }
        set { sourceRaw = newValue.rawValue }
    }

    var muscleGroup: MuscleGroup {
        get { MuscleGroup(rawValue: muscleGroupRaw) ?? .chest }
        set { muscleGroupRaw = newValue.rawValue }
    }

    var type: ExerciseType {
        get { ExerciseType(rawValue: typeRaw) ?? .machine }
        set { typeRaw = newValue.rawValue }
    }

    var loadBasis: LoadBasis? {
        get { loadBasisRaw.flatMap(LoadBasis.init(rawValue:)) }
        set { loadBasisRaw = newValue?.rawValue }
    }

    // Convenience init
    init(name: String,
         source: Source,
         muscleGroup: MuscleGroup,
         type: ExerciseType,
         loadBasis: LoadBasis? = nil,
         youtubeVideoID: String? = nil) {
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.sourceRaw = source.rawValue
        self.muscleGroupRaw = muscleGroup.rawValue
        self.typeRaw = type.rawValue
        self.loadBasisRaw = loadBasis?.rawValue
        self.youtubeVideoID = youtubeVideoID
    }
}
