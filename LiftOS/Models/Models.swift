import Foundation
import SwiftUI

struct ExerciseItem: Identifiable, Hashable { let id = UUID(); var name: String; var targetSets: Int; var rirTarget: Int; var typeLabel: String? = nil; var suggestedNextWeight: Double? = nil; var suggestedNextRepTargetLower: Int? = nil; var suggestedNextRepTargetUpper: Int? = nil }
struct ExerciseSet: Identifiable, Hashable { let id = UUID(); var index: Int; var weight: Double?; var reps: Int?; var rir: Int?; var done: Bool = false }
struct WorkoutSession: Identifiable { let id = UUID(); var title: String; var exercises: [ExerciseItem] }

enum WeightUnit: String, CaseIterable, Identifiable { case lb, kg; var id: String { rawValue }; var display: String { rawValue.uppercased() }; var step: Double { self == .kg ? 2.5 : 5.0 } }
struct UserPrefs { @AppStorage("weightUnit") var weightUnit: WeightUnit = .lb }
