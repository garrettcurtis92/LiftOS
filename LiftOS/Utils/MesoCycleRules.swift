import Foundation
import SwiftUI

enum MesocycleRules { static func rirTarget(forWeek week: Int) -> Int { switch week { case 1: return 3; case 2: return 2; case 3: return 1; case 4: return 1; case 5: return 0; default: return 3 } } }
struct MesoPrefs { @AppStorage("currentWeek") var currentWeek: Int = 1 }
