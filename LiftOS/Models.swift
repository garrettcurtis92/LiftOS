//
//  Models.swift
//  LiftOS
//
//  Created by Garrett Curtis on 9/13/25.
//
import Foundation
import SwiftUI

struct ExerciseItem: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var targetSets: Int
    var rirTarget: Int // placeholder from meso rules (e.g., 3 for Week 1)
}

struct ExerciseSet: Identifiable, Hashable {
    let id = UUID()
    var index: Int
    var weight: Double?  // kg or lb (unit agnostic for now)
    var reps: Int?
    var rir: Int?        // user-entered after the set
    var done: Bool = false
}

struct WorkoutSession: Identifiable {
    let id = UUID()
    var title: String
    var exercises: [ExerciseItem]
}

enum WeightUnit: String, CaseIterable, Identifiable {
    case lb, kg
    var id: String { rawValue }

    var display: String { rawValue.uppercased() }
    var step: Double { self == .kg ? 2.5 : 5.0 } // typical plate jumps
}

struct UserPrefs {
    @AppStorage("weightUnit") var weightUnit: WeightUnit = .lb
}
