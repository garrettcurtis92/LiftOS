import SwiftUI

struct SetEntryView: View { /* moved under WorkoutSessionView feature in case used here */
    @Environment(\.dismiss) private var dismiss
    @AppStorage("weightUnit") private var weightUnit: WeightUnit = .lb
    let exerciseName: String
    let rirTarget: Int
    var initial: ExerciseSet
    var onSave: (ExerciseSet, Int) -> Void
    var onCancel: () -> Void
    @State private var weightText: String = ""
    @State private var repsText: String = ""
    @State private var rirText: String = ""
    @State private var restSeconds: Double = 90
    var body: some View {
        NavigationStack {
            Form {
                Section { Text(exerciseName).font(TypeScale.title()) }
                Section("Entry") { TextField("Weight (\(weightUnit.display))", text: $weightText).keyboardType(.decimalPad); TextField("Reps (target RIR \(rirTarget))", text: $repsText).keyboardType(.numberPad); TextField("RIR (0–4)", text: $rirText).keyboardType(.numberPad) }
                Section("Rest Timer") { VStack(alignment: .leading, spacing: 8) { Text("\(Int(restSeconds)) seconds").font(TypeScale.headline()); Slider(value: $restSeconds, in: 45...180, step: 15) } }
            }
            .navigationTitle("Set Entry")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { onCancel(); dismiss() } }; ToolbarItem(placement: .confirmationAction) { Button("Save") { var result = initial; result.weight = Double(weightText.replacingOccurrences(of: ",", with: ".")); result.reps = Int(repsText); result.rir = Int(rirText); result.done = true; onSave(result, Int(restSeconds)); dismiss() }.disabled(Int(repsText) == nil) } }
        }
    }
}
