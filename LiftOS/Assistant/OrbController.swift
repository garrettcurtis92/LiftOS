//
//  OrbController.swift
//  LiftOS
//
//  Created by GitHub Copilot on 10/1/25.
//

import SwiftUI
import Combine

/// Where the orb appears
enum OrbScope: String, Codable, CaseIterable {
    case global       // show on every tab
    case perTab       // separate visibility/position per tab
    case trainOnly    // only visible on Train tab
}

/// Side to snap against
enum OrbSnapSide: String, Codable { case leading, trailing }

/// A serializable position relative to the safe area container.
struct OrbPosition: Codable, Equatable {
    var x: CGFloat = 0.85   // 0..1 across width
    var y: CGFloat = 0.80   // 0..1 down height
    var side: OrbSnapSide = .trailing
}

@MainActor
final class OrbController: ObservableObject {
    // Policy
    @AppStorage("orb.scope") var storedScope: String = OrbScope.global.rawValue
    var scope: OrbScope {
        get { OrbScope(rawValue: storedScope) ?? .global }
        set { storedScope = newValue.rawValue }
    }
    @AppStorage("orb.isHidden") var isHidden: Bool = false

    // Position (global)
    @AppStorage("orb.position") private var storedPosition: Data = Data()
    @Published var position: OrbPosition = .init()

    // Per-tab positions if you choose perTab
    @AppStorage("orb.position.train") private var storedTrainPos: Data = Data()
    @AppStorage("orb.position.mesocycles") private var storedMesosPos: Data = Data()
    @AppStorage("orb.position.exercises") private var storedExercisesPos: Data = Data()
    @AppStorage("orb.position.settings") private var storedSettingsPos: Data = Data()

    // Sheet state
    @Published var isPresentingSheet: Bool = false

    init() {
        // restore global position
        if let decoded = try? JSONDecoder().decode(OrbPosition.self, from: storedPosition), storedPosition.isEmpty == false {
            position = decoded
        }
    }

    func position(for tab: String) -> OrbPosition {
        switch scope {
        case .global, .trainOnly: return position
        case .perTab:
            let data: Data = {
                switch tab {
                case "train": return storedTrainPos
                case "mesocycles": return storedMesosPos
                case "exercises": return storedExercisesPos
                case "settings": return storedSettingsPos
                default: return storedTrainPos
                }
            }()
            if let decoded = try? JSONDecoder().decode(OrbPosition.self, from: data), data.isEmpty == false {
                return decoded
            }
            return .init()
        }
    }

    func setPosition(_ pos: OrbPosition, for tab: String) {
        switch scope {
        case .global, .trainOnly:
            position = pos
            storedPosition = (try? JSONEncoder().encode(pos)) ?? Data()
        case .perTab:
            let data = (try? JSONEncoder().encode(pos)) ?? Data()
            switch tab {
            case "train": storedTrainPos = data
            case "mesocycles": storedMesosPos = data
            case "exercises": storedExercisesPos = data
            case "settings": storedSettingsPos = data
            default: storedTrainPos = data
            }
        }
    }

    func shouldShow(for tab: String) -> Bool {
        guard !isHidden else { return false }
        switch scope {
        case .global, .perTab: return true
        case .trainOnly: return tab == "train"
        }
    }
}
