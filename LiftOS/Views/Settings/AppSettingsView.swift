// Settings feature root
import SwiftUI

struct SettingsView: View {
    @AppStorage("weightUnit") private var weightUnit: WeightUnit = .lb
    @AppStorage("currentWeek") private var currentWeek: Int = 1
    @AppStorage("scheduleMode") private var scheduleMode: ScheduleMode = .fixedWeekdays
    @AppStorage("daysPerWeek") private var daysPerWeek: Int = 3
    @AppStorage("totalWeeks") private var totalWeeks: Int = 5
    @AppStorage("currentDayIx") private var currentDayIx: Int = 0
    
    // Session & Haptics settings
    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true
    @AppStorage("provisionalWeightDim") private var provisionalWeightDim: Bool = false
    @AppStorage("restTimerAutoStart") private var restTimerAutoStart: Bool = true

    var body: some View {
        ScrollView {
            VStack(spacing: FitnessDS.Space.lg.rawValue) {
                // Appearance Section
                appearanceSection
                
                // Session Section  
                sessionSection
                
                // Haptics & Sounds Section
                hapticsSection
                
                // Units Section
                unitsSection
                
                // Mesocycle Settings Section
                mesocycleSection
            }
            .padding(FitnessDS.Space.lg.rawValue)
        }
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .onChange(of: totalWeeks) { _, newValue in
            // Clamp currentWeek if totalWeeks decreases below the current selection
            if currentWeek > newValue { currentWeek = newValue }
        }
        .onChange(of: daysPerWeek) { _, newValue in
            // Clamp selected day index into new range
            let maxIx = max(newValue - 1, 0)
            if currentDayIx > maxIx { currentDayIx = maxIx }
        }
    }
    
    // MARK: - Appearance Section
    
    @ViewBuilder
    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: FitnessDS.Space.md.rawValue) {
            sectionHeader("Appearance", icon: "paintbrush.fill", color: .purple)
            
            VStack(spacing: FitnessDS.Space.sm.rawValue) {
                NavigationLink {
                    AppearanceView()
                } label: {
                    settingsRow(
                        title: "Theme & Accent",
                        description: "Customize colors and appearance",
                        icon: "circles.hexagongrid",
                        showChevron: true
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(FitnessDS.Space.lg.rawValue)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: FitnessDS.Corners.card))
            .fitnessShadow(FitnessDS.Shadows.cardShadow)
        }
    }
    
    // MARK: - Session Section
    
    @ViewBuilder
    private var sessionSection: some View {
        VStack(alignment: .leading, spacing: FitnessDS.Space.md.rawValue) {
            sectionHeader("Session", icon: "timer", color: .blue)
            
            VStack(spacing: FitnessDS.Space.sm.rawValue) {
                settingsToggleRow(
                    title: "Rest Timer Auto-Start",
                    description: "Automatically start rest timer after completing a set",
                    icon: "play.fill",
                    isOn: $restTimerAutoStart
                )
                
                Divider()
                    .padding(.horizontal, FitnessDS.Space.lg.rawValue)
                
                settingsToggleRow(
                    title: "Dim Provisional Weight",
                    description: "Make estimated weights appear dimmed for clarity",
                    icon: "eye.slash",
                    isOn: $provisionalWeightDim
                )
            }
            .padding(FitnessDS.Space.lg.rawValue)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: FitnessDS.Corners.card))
            .fitnessShadow(FitnessDS.Shadows.cardShadow)
        }
    }
    
    // MARK: - Haptics & Sounds Section
    
    @ViewBuilder
    private var hapticsSection: some View {
        VStack(alignment: .leading, spacing: FitnessDS.Space.md.rawValue) {
            sectionHeader("Haptics & Sounds", icon: "iphone.radiowaves.left.and.right", color: .orange)
            
            VStack(spacing: FitnessDS.Space.sm.rawValue) {
                settingsToggleRow(
                    title: "Haptic Feedback",
                    description: "Feel tactile responses for interactions and completions",
                    icon: "hand.tap",
                    isOn: $hapticsEnabled
                )
            }
            .padding(FitnessDS.Space.lg.rawValue)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: FitnessDS.Corners.card))
            .fitnessShadow(FitnessDS.Shadows.cardShadow)
        }
    }
    
    // MARK: - Units Section
    
    @ViewBuilder
    private var unitsSection: some View {
        VStack(alignment: .leading, spacing: FitnessDS.Space.md.rawValue) {
            sectionHeader("Units", icon: "scalemass", color: .green)
            
            VStack(spacing: FitnessDS.Space.sm.rawValue) {
                HStack(spacing: FitnessDS.Space.md.rawValue) {
                    HStack(spacing: FitnessDS.Space.sm.rawValue) {
                        Image(systemName: "dumbbell.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.green)
                            .frame(width: 24, height: 24)
                        
                        VStack(alignment: .leading, spacing: FitnessDS.Space.xs.rawValue) {
                            Text("Weight")
                                .font(FitnessDS.Typography.headlineSmall)
                                .foregroundStyle(.primary)
                            
                            Text("Default unit for all weight measurements")
                                .font(FitnessDS.Typography.captionMedium)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Picker("Weight Unit", selection: $weightUnit) {
                        ForEach(WeightUnit.allCases) { unit in
                            Text(unit.display).tag(unit)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 100)
                }
            }
            .padding(FitnessDS.Space.lg.rawValue)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: FitnessDS.Corners.card))
            .fitnessShadow(FitnessDS.Shadows.cardShadow)
        }
    }
    
    // MARK: - Mesocycle Section
    
    @ViewBuilder
    private var mesocycleSection: some View {
        VStack(alignment: .leading, spacing: FitnessDS.Space.md.rawValue) {
            sectionHeader("Mesocycle", icon: "calendar", color: .red)
            
            VStack(spacing: FitnessDS.Space.lg.rawValue) {
                // Current Week
                VStack(spacing: FitnessDS.Space.sm.rawValue) {
                    HStack {
                        Text("Current Week")
                            .font(FitnessDS.Typography.headlineSmall)
                            .foregroundStyle(.primary)
                        Spacer()
                    }
                    
                    Picker("Current Week", selection: $currentWeek) {
                        ForEach(1...max(totalWeeks, 1), id: \.self) { w in
                            Text("Week \(w)").tag(w)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Divider()
                
                // Total Weeks
                HStack(spacing: FitnessDS.Space.md.rawValue) {
                    VStack(alignment: .leading, spacing: FitnessDS.Space.xs.rawValue) {
                        Text("Total Weeks")
                            .font(FitnessDS.Typography.headlineSmall)
                            .foregroundStyle(.primary)
                        
                        Text("RIR target auto-fills by week")
                            .font(FitnessDS.Typography.captionMedium)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Stepper(value: $totalWeeks, in: 1...12) {
                        Text("\(totalWeeks)")
                            .font(FitnessDS.Typography.numericMedium)
                            .foregroundStyle(.primary)
                    }
                }
                
                Divider()
                
                // Schedule Mode  
                VStack(spacing: FitnessDS.Space.sm.rawValue) {
                    HStack {
                        Text("Schedule Mode")
                            .font(FitnessDS.Typography.headlineSmall)
                            .foregroundStyle(.primary)
                        Spacer()
                    }
                    
                    Picker("Mode", selection: $scheduleMode) {
                        ForEach(ScheduleMode.allCases) { mode in
                            Text(mode.display).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    Text(scheduleMode == .fixedWeekdays 
                         ? "Shows weekday labels (Mon, Wed, Fri…)" 
                         : "Shows ordered days (Day 1, Day 2, Day 3…)")
                        .font(FitnessDS.Typography.captionMedium)
                        .foregroundStyle(.secondary)
                }
                
                Divider()
                
                // Days per Week
                HStack(spacing: FitnessDS.Space.md.rawValue) {
                    VStack(alignment: .leading, spacing: FitnessDS.Space.xs.rawValue) {
                        Text("Days per Week")
                            .font(FitnessDS.Typography.headlineSmall)
                            .foregroundStyle(.primary)
                        
                        Text("Number of training days per week")
                            .font(FitnessDS.Typography.captionMedium)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Stepper(value: $daysPerWeek, in: 2...6) {
                        Text("\(daysPerWeek)")
                            .font(FitnessDS.Typography.numericMedium)
                            .foregroundStyle(.primary)
                    }
                }
            }
            .padding(FitnessDS.Space.lg.rawValue)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: FitnessDS.Corners.card))
            .fitnessShadow(FitnessDS.Shadows.cardShadow)
        }
    }
    
    // MARK: - Helper Views
    
    @ViewBuilder
    private func sectionHeader(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: FitnessDS.Space.sm.rawValue) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.15), in: RoundedRectangle(cornerRadius: FitnessDS.Corners.small))
            
            Text(title)
                .font(FitnessDS.Typography.displaySmall)
                .foregroundStyle(.primary)
            
            Spacer()
        }
    }
    
    @ViewBuilder
    private func settingsRow(title: String, description: String, icon: String, showChevron: Bool = false) -> some View {
        HStack(spacing: FitnessDS.Space.md.rawValue) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.purple)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: FitnessDS.Space.xs.rawValue) {
                Text(title)
                    .font(FitnessDS.Typography.headlineSmall)
                    .foregroundStyle(.primary)
                
                Text(description)
                    .font(FitnessDS.Typography.captionMedium)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
        }
    }
    
    @ViewBuilder
    private func settingsToggleRow(title: String, description: String, icon: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: FitnessDS.Space.md.rawValue) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(isOn.wrappedValue ? .blue : .secondary)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: FitnessDS.Space.xs.rawValue) {
                Text(title)
                    .font(FitnessDS.Typography.headlineSmall)
                    .foregroundStyle(.primary)
                
                Text(description)
                    .font(FitnessDS.Typography.captionMedium)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: isOn)
                .labelsHidden()
                .scaleEffect(0.9)
                .onChange(of: isOn.wrappedValue) { _, newValue in
                    if newValue {
                        #if canImport(UIKit)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        #endif
                    }
                }
        }
    }
}
