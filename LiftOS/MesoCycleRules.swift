//
//  MesoCycleRules.swift
//  LiftOS
//
//  Created by Garrett Curtis on 9/13/25.
//
import Foundation
import SwiftUI

enum MesocycleRules {
    static func rirTarget(forWeek week: Int) -> Int {
        switch week {
        case 1: return 3
        case 2: return 2
        case 3: return 1
        case 4: return 1 // 0–1; we’ll surface the “0–1” nuance later
        case 5: return 0 // PR week (we’ll special-case copy later)
        default: return 3 // deload would be 3–4 RIR with volume reduction later
        }
    }
}

struct MesoPrefs {
    @AppStorage("currentWeek") var currentWeek: Int = 1  // 1...6
}
