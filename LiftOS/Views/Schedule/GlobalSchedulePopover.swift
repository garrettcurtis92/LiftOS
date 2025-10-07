// Full schedule popover used across tabs
import SwiftUI
import SwiftData

struct GlobalSchedulePopover: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @AppStorage("scheduleMode")  private var scheduleMode: ScheduleMode = .fixedWeekdays
    @AppStorage("daysPerWeek")   private var daysPerWeek: Int = 3
    @AppStorage("currentWeek")   private var currentWeek: Int = 1
    @AppStorage("currentDayIx")  private var currentDayIx: Int = 0
    @AppStorage("totalWeeks")    private var totalWeeks: Int = 5

    var mesocycleID: UUID? = nil

    @State private var pendingSelection: (week: Int, dayIx: Int)? = nil
    @State private var showWeekSwitchAlert = false
    @State private var activeMesocycle: Mesocycle? = nil

    @State private var selectedWeekPreview: Int? = nil
    @State private var selectedDayPreview: Int? = nil
    @State private var loadedLogs: [WorkoutLogEntry] = []
    @State private var lastUpdatedAt: Date? = nil

    @Namespace private var selectionNS

    // Adaptive layout: columns match the configured workouts per week
    private var dayColumns: [GridItem] {
        let count = max(activeMesocycle?.daysPerWeek ?? daysPerWeek, 1)
        return Array(repeating: GridItem(.flexible(minimum: 44), spacing: FitnessDS.Space.sm.rawValue, alignment: .center), count: count)
    }
    
    private var totalWeeksToShow: Int {
        max(activeMesocycle?.weekCount ?? totalWeeks, 1)
    }

    private func completedDays(for week: Int) -> Set<Int> {
        if let id = mesocycleID {
            let d = FetchDescriptor<MesoCompletion>(predicate: #Predicate { $0.week == week && $0.mesocycleID == id })
            let items = (try? modelContext.fetch(d)) ?? []
            return Set(items.map { $0.dayIx })
        } else {
            let d = FetchDescriptor<MesoCompletion>(predicate: #Predicate { $0.week == week })
            let items = (try? modelContext.fetch(d)) ?? []
            return Set(items.map { $0.dayIx })
        }
    }

    private func colorForDay(_ dayIx: Int, week: Int, done: Set<Int>) -> Color {
        if done.contains(dayIx) { return MulticolorAccent.color(for: .success) }
        if week == currentWeek && dayIx == currentDayIx { return MulticolorAccent.color(for: .navigation) }
        return .clear
    }

    private func strokeColorForDay(_ dayIx: Int, week: Int, done: Set<Int>) -> Color {
        if done.contains(dayIx) { return MulticolorAccent.color(for: .success).opacity(0.7) }
        if week == currentWeek && dayIx == currentDayIx { return MulticolorAccent.color(for: .navigation).opacity(0.7) }
        return Color.secondary.opacity(0.35)
    }

    private func textColorForDay(_ dayIx: Int, week: Int, done: Set<Int>) -> Color {
        let bg = colorForDay(dayIx, week: week, done: done)
        return bg == .clear ? .primary : .white
    }
    
    private func nextAllowedPosition() -> (week: Int, dayIx: Int) {
        if let id = mesocycleID, let pos = MesoProgress.nextPosition(for: id, in: modelContext, daysPerWeek: activeMesocycle?.daysPerWeek ?? daysPerWeek, weekCount: activeMesocycle?.weekCount ?? totalWeeks) {
            return pos
        }
        let totalW = max(totalWeeks, 1)
        let dPerW = max(daysPerWeek, 1)
        for w in 1...totalW {
            let done = completedDays(for: w)
            for i in 0..<dPerW { if !done.contains(i) { return (w, i) } }
        }
        return (currentWeek, currentDayIx)
    }
    
    private func isAllowed(week: Int, dayIx: Int) -> Bool {
        let allowed = nextAllowedPosition()
        if week > allowed.week { return false }
        if week == allowed.week && dayIx > allowed.dayIx { return false }
        return true
    }

    private func reloadLogsIfPossible() {
        guard let id = mesocycleID, let week = selectedWeekPreview, let day = selectedDayPreview else {
            loadedLogs = []
            lastUpdatedAt = nil
            return
        }
        let _meso = id
        let _week = week
        let _day = day
        let d = FetchDescriptor<WorkoutLogEntry>(
            predicate: #Predicate { $0.mesocycleID == _meso && $0.week == _week && $0.dayIx == _day }
        )
        let fetched = (try? modelContext.fetch(d)) ?? []
        loadedLogs = fetched
        lastUpdatedAt = fetched.map { $0.updatedAt }.max()
    }
    
    private func iconNameFor(_ key: String) -> String {
        // Heuristic icon mapping; adjust as desired
        let k = key.lowercased()
        if k.contains("barbell") || k.contains("squat") || k.contains("bench") || k.contains("deadlift") { return "barbell" }
        if k.contains("dumbbell") || k.contains("db ") { return "dumbbell" }
        if k.contains("smith") { return "figure.strengthtraining.functional" }
        if k.contains("cable") || k.contains("pulldown") { return "bolt" }
        if k.contains("assist") || k.contains("pull-up") || k.contains("chin") { return "figure.pullup" }
        return "dumbbell"
    }
    
    private func heaviest(_ entries: [WorkoutLogEntry]) -> (weight: Double, reps: Int, unit: WeightUnit)? {
        let tops = entries.compactMap { e -> (Double, Int, WeightUnit)? in
            if let w = e.weight, let r = e.reps { return (w, r, e.unit) }
            return nil
        }
        if let best = tops.max(by: { $0.0 < $1.0 }) { return (best.0, best.1, best.2) }
        return nil
    }
    
    private func computeCompletion(for week: Int, dayIx: Int) -> (ratio: Double, totalPlanned: Int, totalLogged: Int) {
        guard let mesoID = mesocycleID, let meso = activeMesocycle else { return (0, 0, 0) }
        // Planned sets by key
        let planned: [(key: String, sets: Int)] = {
            if let snapshot = meso.planSnapshot, dayIx < snapshot.count {
                let d = snapshot[dayIx]
                return d.exercises.map { (PlanKey.normalize($0.exerciseDisplayName), $0.defaultSets) }
            } else if dayIx < meso.days.count {
                let day = meso.days.sorted(by: { $0.index < $1.index })[dayIx]
                return day.selections.compactMap { sel in
                    if let ex = sel.exercise { return (PlanKey.normalize(ex.name), 3) }
                    return nil
                }
            }
            return []
        }()
        let totalPlanned = planned.reduce(0) { $0 + $1.sets }
        guard totalPlanned > 0 else { return (0, 0, 0) }
        // Fetch all logs for this day
        let _meso = mesoID
        let _week = week
        let _day = dayIx
        let d = FetchDescriptor<WorkoutLogEntry>(predicate: #Predicate { $0.mesocycleID == _meso && $0.week == _week && $0.dayIx == _day })
        let logs = (try? modelContext.fetch(d)) ?? []
        let doneCount = logs.filter { $0.done && $0.weight != nil && $0.reps != nil }.count
        let ratio = min(1.0, Double(doneCount) / Double(totalPlanned))
        return (ratio, totalPlanned, doneCount)
    }
    
    private func formatWeight(_ w: Double, unit: WeightUnit) -> String {
        let rounded = (w.rounded() == w) ? "\(Int(w))" : String(format: "%.1f", w)
        return unit == .kg ? "\(rounded) kg" : "\(rounded) lb"
    }

    private func handleSelection(week: Int, dayIx: Int) {
        Haptics.tap()
        let allowed = isAllowed(week: week, dayIx: dayIx)
        guard allowed else {
            #if canImport(UIKit)
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            #endif
            return
        }
        selectedWeekPreview = week
        selectedDayPreview = dayIx
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
        reloadLogsIfPossible()
    }


    @ViewBuilder
    private func entriesList(for dayIx: Int) -> some View {
        // Build snapshot order mapping using helper
        let order = plannedOrder(for: dayIx)
        let orderedKeys: [String] = order.orderedKeys
        let displayNameByKey: [String: String] = order.displayNameByKey

        if loadedLogs.isEmpty {
            ContentUnavailableView("No entries recorded.", systemImage: "clock")
        } else {
            // Pre-group once to keep the ForEach body tiny (helps type-checker)
            let grouped: [String: [WorkoutLogEntry]] = Dictionary(grouping: loadedLogs, by: { $0.exerciseKey })
            ForEach(orderedKeys, id: \.self) { key in
                let entries: [WorkoutLogEntry] = (grouped[key] ?? []).sorted(by: { $0.setIndex < $1.setIndex })
                if !entries.isEmpty {
                    exerciseSection(
                        key: key,
                        displayName: displayNameByKey[key] ?? key,
                        entries: entries
                    )
                }
            }
        }
    }

    @ViewBuilder
    private func exerciseSection(key: String, displayName: String, entries: [WorkoutLogEntry]) -> some View {
        VStack(alignment: .leading, spacing: FitnessDS.Space.md.rawValue) {
            headerRow(for: key, displayName: displayName, entries: entries)
            
            VStack(spacing: FitnessDS.Space.xs.rawValue) {
                ForEach(entries) { e in
                    entryRow(e)
                }
            }
        }
        .padding(FitnessDS.Space.lg.rawValue)
        .background(
            RoundedRectangle(cornerRadius: FitnessDS.Corners.card)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: FitnessDS.Corners.card)
                .stroke(.separator.opacity(0.3), lineWidth: 1)
        )
        .fitnessShadow(FitnessDS.Shadows.cardShadow)
        .padding(.vertical, FitnessDS.Space.xs.rawValue)
    }

    @ViewBuilder
    private func headerRow(for key: String, displayName: String, entries: [WorkoutLogEntry]) -> some View {
        HStack(spacing: FitnessDS.Space.md.rawValue) {
            // Exercise type icon with color coding
            Image(systemName: iconNameFor(key))
                .font(.title3)
                .foregroundStyle(FitnessDS.FitnessTint.forKey(key))
                .frame(width: 32, height: 32)
                .background(FitnessDS.FitnessTint.forKey(key).opacity(0.15), in: Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(displayName)
                    .font(FitnessDS.Typography.headlineSmall)
                    .foregroundStyle(.primary)
                
                if let top = heaviest(entries) {
                    Text("Heaviest: \(formatWeight(top.weight, unit: top.unit)) × \(top.reps)")
                        .font(FitnessDS.Typography.captionMedium)
                        .foregroundStyle(.secondary)
                        .numericTextTransitionIfAvailable()
                }
            }
            Spacer()
        }
    }

    @ViewBuilder
    private func entryRow(_ e: WorkoutLogEntry) -> some View {
        HStack(spacing: FitnessDS.Space.md.rawValue) {
            // Set number indicator
            Text("\(e.setIndex)")
                .font(FitnessDS.Typography.captionLarge)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .frame(width: 20, height: 20)
                .background(.thinMaterial, in: Circle())
            
            Spacer()
            
            // Weight and reps display
            if let w = e.weight, let r = e.reps {
                HStack(spacing: FitnessDS.Space.xs.rawValue) {
                    Text(formatWeight(w, unit: e.unit))
                        .font(FitnessDS.Typography.numericSmall)
                        .foregroundStyle(.primary)
                    
                    Text("×")
                        .font(FitnessDS.Typography.captionMedium)
                        .foregroundStyle(.tertiary)
                    
                    Text("\(r)")
                        .font(FitnessDS.Typography.numericSmall)
                        .foregroundStyle(.primary)
                }
                .padding(.horizontal, FitnessDS.Space.sm.rawValue)
                .padding(.vertical, FitnessDS.Space.xs.rawValue)
                .background(.thinMaterial, in: Capsule())
            } else if e.done && e.weight == nil && e.reps == nil {
                Text("Skipped")
                    .font(FitnessDS.Typography.captionMedium)
                    .foregroundStyle(.orange)
                    .padding(.horizontal, FitnessDS.Space.sm.rawValue)
                    .padding(.vertical, FitnessDS.Space.xs.rawValue)
                    .background(.orange.opacity(0.15), in: Capsule())
            } else {
                Text("—")
                    .font(FitnessDS.Typography.captionMedium)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, FitnessDS.Space.xs.rawValue)
    }

    private func plannedOrder(for dayIx: Int) -> (orderedKeys: [String], displayNameByKey: [String: String]) {
        var orderedKeys: [String] = []
        var displayNameByKey: [String: String] = [:]
        if let meso = activeMesocycle, let snapshot = meso.planSnapshot, dayIx < snapshot.count {
            let day = snapshot[dayIx]
            orderedKeys = day.exercises.map { PlanKey.normalize($0.exerciseDisplayName) }
            for ex in day.exercises {
                displayNameByKey[PlanKey.normalize(ex.exerciseDisplayName)] = ex.exerciseDisplayName
            }
        } else if let meso = activeMesocycle, dayIx < meso.days.count {
            let day = meso.days.sorted(by: { $0.index < $1.index })[dayIx]
            let sels = day.selections.compactMap { $0.exercise }
            orderedKeys = sels.map { PlanKey.normalize($0.name) }
            for ex in sels {
                displayNameByKey[PlanKey.normalize(ex.name)] = ex.name
            }
        }
        return (orderedKeys, displayNameByKey)
    }

    @ViewBuilder
    private func headerPickerView() -> some View {
        VStack(spacing: 8) {
            Text("Week \(selectedWeekPreview ?? currentWeek)")
                .font(.title3).fontWeight(.semibold)
                .contentTransition(.numericText())
            Picker("Week", selection: Binding(
                get: { selectedWeekPreview ?? currentWeek },
                set: { newVal in selectedWeekPreview = newVal }
            )) {
                ForEach(1...totalWeeksToShow, id: \.self) { w in
                    Text("Week \(w)").tag(w)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    @ViewBuilder
    private func weeksGrid() -> some View {
        ForEach(1...totalWeeksToShow, id: \.self) { week in
            let daysList = visibleDays(mode: scheduleMode, daysPerWeek: activeMesocycle?.daysPerWeek ?? daysPerWeek)
            let doneDays: Set<Int> = completedDays(for: week)
            let selectedW: Int = (selectedWeekPreview ?? currentWeek)
            let selectedIx: Int = (selectedDayPreview ?? currentDayIx)

            WeekRow(
                week: week,
                days: daysList,
                dayColumns: dayColumns,
                doneDays: doneDays,
                selectedWeek: selectedW,
                selectedDayIx: selectedIx,
                selectionNS: selectionNS,
                colorForDay: { ix, w, done in colorForDay(ix, week: w, done: done) },
                strokeColorForDay: { ix, w, done in strokeColorForDay(ix, week: w, done: done) },
                textColorForDay: { ix, w, done in textColorForDay(ix, week: w, done: done) },
                onSelect: { w, ix in handleSelection(week: w, dayIx: ix) }
            )
        }
    }

    @ViewBuilder
    private func entriesSection() -> some View {
        VStack(alignment: .leading, spacing: FitnessDS.Space.sm.rawValue) {
            HStack {
                Text("Entries")
                    .font(FitnessDS.Typography.headlineMedium)
                Spacer()
                if let ts = lastUpdatedAt {
                    Text(ts, style: .time)
                        .font(FitnessDS.Typography.captionMedium)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Last updated")
                }
            }

            let week = selectedWeekPreview ?? currentWeek
            let dayIx = selectedDayPreview ?? currentDayIx

            // Completion ring & chips
            let stats = computeCompletion(for: week, dayIx: dayIx)
            completionStatsView(stats)

            entriesList(for: dayIx)
        }
    }

    @ViewBuilder
    private func mainContent() -> some View {
        VStack(spacing: FitnessDS.Space.md.rawValue) {
            headerPickerView()
                .padding(.horizontal, FitnessDS.Space.lg.rawValue)
                .padding(.top, FitnessDS.Space.sm.rawValue)

            weeksGrid()
                .padding(.horizontal, FitnessDS.Space.lg.rawValue)

            entriesSection()
                .padding(.horizontal, FitnessDS.Space.lg.rawValue)
                .padding(.bottom, FitnessDS.Space.lg.rawValue)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: FitnessDS.Space.sm.rawValue) {
                Text("Schedule")
                    .font(FitnessDS.Typography.displayLarge)
                    .foregroundStyle(.primary)
                
                if let lastUpdated = lastUpdatedAt {
                    Text("Last updated \(lastUpdated.formatted(.relative(presentation: .named)))")
                        .font(FitnessDS.Typography.captionMedium)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, FitnessDS.Space.lg.rawValue)
            .padding(.top, FitnessDS.Space.lg.rawValue)
            .padding(.bottom, FitnessDS.Space.md.rawValue)

            // Full mesocycle grid: totalWeeks rows x days
            ScrollView {
                mainContent()
                    .padding(.top, FitnessDS.Space.sm.rawValue)
            }

            // Footer with done button
            HStack {
                Spacer()
                PrimaryButton(title: "Done", systemIcon: "checkmark.circle.fill", style: .success) {
                    dismiss()
                }
                .padding(.horizontal, FitnessDS.Space.lg.rawValue)
                .padding(.bottom, FitnessDS.Space.lg.rawValue)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: FitnessDS.Corners.large, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .clipShape(RoundedRectangle(cornerRadius: FitnessDS.Corners.large, style: .continuous))
        .fitnessShadow(FitnessDS.Shadows.cardShadow)
        .alert("Switch to Week \(pendingSelection?.week ?? 1)?", isPresented: $showWeekSwitchAlert) {
            Button("Cancel", role: .cancel) { pendingSelection = nil }
            Button("Switch") { if let p = pendingSelection { currentWeek = p.week; currentDayIx = p.dayIx }; pendingSelection = nil; dismiss() }
        } message: { Text("Auto-regulated targets apply only to the current week. You can always change back in Settings.") }
        .presentationDetents([.large])
        .task {
            if let id = mesocycleID, let pos = MesoProgress.nextPosition(for: id, in: modelContext, daysPerWeek: daysPerWeek, weekCount: totalWeeks) {
                currentWeek = pos.week
                currentDayIx = pos.dayIx
            }
            if let id = mesocycleID {
                let descriptor = FetchDescriptor<Mesocycle>(predicate: #Predicate { $0.id == id })
                activeMesocycle = try? modelContext.fetch(descriptor).first
            }
            if selectedWeekPreview == nil { selectedWeekPreview = currentWeek }
            if selectedDayPreview == nil { selectedDayPreview = currentDayIx }
            reloadLogsIfPossible()
        }
        .onChange(of: selectedWeekPreview) { _, _ in reloadLogsIfPossible() }
        .onChange(of: selectedDayPreview) { _, _ in reloadLogsIfPossible() }
    }

    @ViewBuilder
    private func completionStatsView(_ stats: (ratio: Double, totalPlanned: Int, totalLogged: Int)) -> some View {
        let percentText = "\(Int(stats.ratio * 100))%"
        HStack(spacing: 12) {
            Gauge(value: stats.ratio) { Text("") } currentValueLabel: {
                Text(percentText)
                    .font(.caption.monospacedDigit())
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .tint(MulticolorAccent.color(for: .calendar))
            .frame(width: 44, height: 44)

            let setsText = "\(stats.totalLogged)/\(stats.totalPlanned) sets"
            Label(setsText, systemImage: "checkmark.seal")
                .font(.footnote.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.thinMaterial, in: Capsule())
        }
    }
}

