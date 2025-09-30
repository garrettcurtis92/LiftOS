// TrainView.swift
import SwiftUI
import SwiftData

struct TrainView: View {
    let mesocycleID: UUID?   // optional so Train tab can do TrainView()
    let onGoToMesocycles: (() -> Void)?
    let onClearActiveMesocycle: (() -> Void)?
    
    @AppStorage("scheduleMode")  private var scheduleMode: ScheduleMode = .fixedWeekdays
    @AppStorage("daysPerWeek")   private var daysPerWeek: Int = 3
    @AppStorage("currentWeek")   private var currentWeek: Int = 1
    @AppStorage("currentDayIx")  private var currentDayIx: Int = 0
    @AppStorage("totalWeeks")    private var totalWeeks: Int = 5
    @State private var showSchedulePopover = false
    @Environment(\.modelContext) private var modelContext
    @State private var activeMesoName: String? = nil

    init(mesocycleID: UUID? = nil, onGoToMesocycles: (() -> Void)? = nil, onClearActiveMesocycle: (() -> Void)? = nil) {
        self.mesocycleID = mesocycleID
        self.onGoToMesocycles = onGoToMesocycles
        self.onClearActiveMesocycle = onClearActiveMesocycle
    }

    private func dayLabel(ix: Int) -> String {
        visibleDays(mode: scheduleMode, daysPerWeek: daysPerWeek)[ix]
    }
    private func plannedPresetForSelectedDay(ix: Int) -> String {
        switch ix { case 0: return "Push"; case 1: return "Pull"; case 2: return "Legs"; default: return "Accessory" }
    }
    private var sessionKey: String { "\(currentWeek)-\(currentDayIx)-\(plannedPresetForSelectedDay(ix: currentDayIx))" }

    var body: some View {
        Group {
            if mesocycleID == nil {
                VStack {
                    ContentUnavailableView {
                        Label("No Active Mesocycle", systemImage: "calendar.badge.exclamationmark")
                    } description: {
                        Text("Create or select a mesocycle to start training.")
                    } actions: {
                        Button {
                            onGoToMesocycles?()
                        } label: {
                            Label("Go to Mesocycles", systemImage: "chart.line.uptrend.xyaxis")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(WorkoutBackground())
                .onAppear { activeMesoName = nil }
            } else {
                WorkoutSessionView(
                    dayLabel: dayLabel(ix: currentDayIx),
                    preset: plannedPresetForSelectedDay(ix: currentDayIx),
                    mesocycleID: mesocycleID,
                    onGoToMesocycles: onGoToMesocycles,
                    onMesocycleCompleted: onClearActiveMesocycle
                )
                .id("\(mesocycleID?.uuidString ?? "none")#\(sessionKey)")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            Haptics.tap()
                            showSchedulePopover = true
                        } label: {
                            Image(systemName: "calendar")
                                .foregroundStyle(MulticolorAccent.color(for: .calendar))
                        }
                        .accessibilityLabel("Schedule")
                    }
                }
                .popover(isPresented: $showSchedulePopover, arrowEdge: .top) {
                    GlobalSchedulePopover(mesocycleID: mesocycleID)
                }
            }
        }
        .navigationTitle(activeMesoName ?? "Train")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: mesocycleID) {
            // Sync schedule prefs with selected mesocycle
            guard let id = mesocycleID else { return }
            let descriptor = FetchDescriptor<Mesocycle>(predicate: #Predicate { $0.id == id })
            if let meso = try? modelContext.fetch(descriptor).first {
                daysPerWeek = meso.daysPerWeek
                if meso.weekCount > 0 { totalWeeks = meso.weekCount }
                activeMesoName = meso.name
            }
        }
    }
        
}

#Preview{TrainView()}
