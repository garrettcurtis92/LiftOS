//
//  MesocycleStore.swift
//  LiftOS
//
//  Created by Garrett Curtis on 10/6/25.
//

import Foundation
import SwiftData

/// Helper functions for managing mesocycle status transitions
enum MesocycleStore {
    
    /// Sets a mesocycle as current, clearing any existing current mesocycle
    static func setCurrent(_ meso: Mesocycle, in context: ModelContext) {
        // Clear any existing current mesocycles
        let descriptor = FetchDescriptor<Mesocycle>()
        if let all = try? context.fetch(descriptor) {
            for m in all where m.status == .current {
                m.status = .planned
            }
        }
        
        // Set the new one as current
        meso.status = .current
        try? context.save()
    }
    
    /// Marks a mesocycle as completed
    static func markCompleted(_ meso: Mesocycle, in context: ModelContext) {
        meso.status = .completed
        try? context.save()
    }
}
