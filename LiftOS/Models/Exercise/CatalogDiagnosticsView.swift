import SwiftUI

struct CatalogDiagnosticsView: View {
    @State private var totalPrefill = 0
    @State private var groups: [(group: String, items: [CatalogItem])] = []

    var body: some View {
        NavigationStack {
            List {
                Section("Totals") {
                    HStack { Text("Prefill (JSON)"); Spacer(); Text("\(totalPrefill)") }
                }
                Section("By Muscle Group") {
                    ForEach(groups, id: \.group) { g in
                        HStack {
                            Text(g.group.capitalized)
                            Spacer()
                            Text("\(g.items.count)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Section("Sample (first 10)") {
                    ForEach(groups.flatMap(\.items).prefix(10)) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.name)
                            Text("\(item.muscleGroup.capitalized) • \(item.type.capitalized)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Catalog Diagnostics")
            .task {
                let gs = ExerciseCatalog.grouped()
                groups = gs
                totalPrefill = gs.reduce(0) { $0 + $1.items.count }
            }
        }
    }
}
