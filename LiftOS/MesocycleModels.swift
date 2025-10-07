// MesocycleModels.swift
// SwiftData models for mesocycle planning and workout sessions

import Foundation
import SwiftData

/// Lightweight, persisted snapshot of a mesocycle plan
struct MesoExerciseTemplate: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    var exerciseDisplayName: String
    var normalizedKey: String
    var defaultSets: Int
    var repRangeLower: Int?
    var repRangeUpper: Int?
    var notes: String?
}

struct MesoDayTemplate: Codable, Hashable {
    var dayIx: Int
    var exercises: [MesoExerciseTemplate]
}

/// Helper for normalizing exercise names into stable keys
enum PlanKey {
    static func normalize(_ name: String) -> String {
        let lower = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let allowed = lower.unicodeScalars.filter { CharacterSet.alphanumerics.contains($0) || $0 == "-" || $0 == "_" || $0 == " " }
        let compact = String(String.UnicodeScalarView(allowed)).replacingOccurrences(of: " ", with: "-")
        return compact
    }
}

enum DayLabelStyle: String, Codable {
    case fixedWeekdays
    case generic
}

@Model
final class Mesocycle {
    enum Status: String, Codable {
        case planned
        case current
        case completed
    }
    
    var id: UUID = UUID()
    var name: String = ""
    var weekCount: Int = 0
    var daysPerWeek: Int = 0
    var status: Status = Status.planned
    var createdAt: Date = Date()

    var startDate: Date? = nil
    var labelStyleRaw: String = "fixedWeekdays"

    var planSnapshotData: Data? = nil

    @Relationship(deleteRule: .cascade)
    var days: [MesoDay] = []

    init(id: UUID = UUID(),
         name: String,
         weekCount: Int,
         daysPerWeek: Int,
         status: Status = .planned,
         createdAt: Date = Date(),
         startDate: Date? = Date(),
         labelStyle: DayLabelStyle = .fixedWeekdays) {
        self.id = id
        self.name = name
        self.weekCount = weekCount
        self.daysPerWeek = daysPerWeek
        self.status = status
        self.createdAt = createdAt
        self.startDate = startDate
        self.labelStyleRaw = labelStyle.rawValue
    }
}

extension Mesocycle {
    var isCurrent: Bool { status == .current }
    var isCompleted: Bool { status == .completed }
}

extension Mesocycle {
    var planSnapshot: [MesoDayTemplate]? {
        get {
            guard let data = planSnapshotData else { return nil }
            return try? JSONDecoder().decode([MesoDayTemplate].self, from: data)
        }
        set {
            planSnapshotData = try? JSONEncoder().encode(newValue)
        }
    }
}

@Model
final class MesoDay {
    var index: Int = 0

    @Relationship(deleteRule: .cascade)
    var selections: [MesoSelection] = []

    @Relationship(inverse: \Mesocycle.days)
    var mesocycle: Mesocycle?

    init(index: Int) {
        self.index = index
    }
}

@Model
final class MesoSelection {
    var muscleGroupRaw: String = ""

    // Reference into the catalog/custom Exercise if available
    @Relationship
    var exercise: Exercise? = nil

    @Relationship(inverse: \MesoDay.selections)
    var day: MesoDay?

    init(muscleGroupRaw: String, exercise: Exercise?) {
        self.muscleGroupRaw = muscleGroupRaw
        self.exercise = exercise
    }
}

@Model
final class MesoCompletion {
    var mesocycleID: UUID = UUID()
    var week: Int = 0
    var dayIx: Int = 0
    var completedAt: Date? = nil

    init(mesocycleID: UUID, week: Int, dayIx: Int, completedAt: Date? = Date()) {
        self.mesocycleID = mesocycleID
        self.week = week
        self.dayIx = dayIx
        self.completedAt = completedAt
    }
}

