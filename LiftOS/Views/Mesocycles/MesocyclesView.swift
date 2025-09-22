import SwiftUI

struct MesocyclesView: View {
    let onOpenTrain: (UUID) -> Void
    // TODO: replace with SwiftData fetch
    @State private var showCreate = false
    @State private var items: [MesocycleItem] = [
        .init(id: UUID(), name: "Quick One G", weekCount: 4, daysPerWeek: 3, isCurrent: true,  isCompleted: false),
        .init(id: UUID(), name: "Garrett",      weekCount: 8, daysPerWeek: 4, isCurrent: false, isCompleted: true),
    ]
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(items, id: \.id) { item in
                    Button {
                        // Safely unwrap AnyHashable → UUID
                        if let uuid = item.id as? UUID {
                            onOpenTrain(uuid)
                        }
                    } label: {
                        MesocycleRowView(
                            item: item,
                            onNewNote: {  },
                            onRename: {  },
                            onCopy: {  },
                            onSummary: {  },
                            onSaveTemplate: {  },
                            onDelete: { delete(item) }
                        )
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                    .swipeActions {
                        Button(role: .destructive) { delete(item) } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle("Mesocycles")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCreate = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Create mesocycle")
                }
            }
            .navigationDestination(isPresented: $showCreate) {
                CreateNewMesoView()
            }
        }
        
    }
    
    private func delete(_ item: MesocycleItem) {
        if let idx = items.firstIndex(of: item) {
            items.remove(at: idx)
#if canImport(UIKit)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
#endif
        }
    }
}
