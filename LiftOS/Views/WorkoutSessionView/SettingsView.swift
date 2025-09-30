import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case system = "System"
    case neutral = "Neutral"
    case deepGreen = "Deep Green"
    case goldAccent = "Gold Accent"
    
    var id: String { rawValue }
}

struct LegacySettingsView: View {
    @AppStorage("appTheme") private var appTheme: String = AppTheme.system.rawValue
    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true
    @AppStorage("provisionalWeightDim") private var provisionalWeightDim: Bool = false
    @AppStorage("restTimerAutoStart") private var restTimerAutoStart: Bool = true
    @AppStorage("weightUnit") private var weightUnit: WeightUnit = .lb
    
    var body: some View {
        NavigationView {
            Form {
                Section(
                    header: Text("Theme"),
                    footer: Text("Choose how the app looks to suit your preference.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                ) {
                    Picker("App Theme", selection: $appTheme) {
                        ForEach(AppTheme.allCases) { theme in
                            Text(theme.rawValue).tag(theme.rawValue)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section(
                    footer: Text("Haptics provide tactile feedback.\nDim provisional weight for clarity.\nAuto-start rest timer saves time.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                ) {
                    Toggle("Haptics", isOn: $hapticsEnabled)
                    Toggle("Dim provisional weight", isOn: $provisionalWeightDim)
                    Toggle("Rest timer auto-start", isOn: $restTimerAutoStart)
                }
                
                Section(
                    header: Text("Units"),
                    footer: Text("Select the unit for weights displayed throughout the app.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                ) {
                    Picker("Weight Unit", selection: $weightUnit) {
                        ForEach(WeightUnit.allCases) { unit in
                            Text(unit.rawValue).tag(unit)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("Settings")
        }
    }
}
