//  CatalogValidator.swift
//  LiftOS
//
//  Debug-only validator for the exercises catalog. It prints actionable warnings
//  about malformed entries or inconsistencies. This file is safe to include in
//  all builds; it only runs under DEBUG when explicitly invoked.

import Foundation

#if DEBUG
struct CatalogValidator {
    static func run() {
        // Validate rules loaded from the legacy ExerciseProgressionCatalog
        let rules = ExerciseProgressionCatalog.shared.allRules()
        var seenNames = Set<String>()
        var duplicates = [String]()

        for r in rules {
            let key = r.name.lowercased()
            if !seenNames.insert(key).inserted { duplicates.append(r.name) }

            // Unknown equipment type
            if r.equipType == .unknown {
                print("[CatalogValidator] Unknown equipType for exercise: \(r.name)")
            }

            // Weight progression must have weightIncrement
            if r.progression == .weight && r.weightIncrement == nil {
                print("[CatalogValidator] Missing weightIncrement for weight-progressed exercise: \(r.name)")
            }

            // Assisted semantics check
            if r.equipType == .machineAssistance {
                if r.minAssistance == nil || r.assistanceStep == nil {
                    print("[CatalogValidator] Assisted rule missing minAssistance or assistanceStep: \(r.name)")
                }
                if let minA = r.minAssistance, let maxA = r.maxAssistance, minA > maxA {
                    print("[CatalogValidator] Assisted rule has minAssistance > maxAssistance: \(r.name)")
                }
            }
        }

        if !duplicates.isEmpty {
            let list = duplicates.joined(separator: ", ")
            print("[CatalogValidator] Duplicate exercise names after lowercasing: \(list)")
        }
    }
}
#endif
