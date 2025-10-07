//
//  MesocycleRowView.swift
//  LiftOS
//
//  Created by Garrett Curtis on 9/19/25.
//
// MesocycleRowView.swift
import SwiftUI

// MARK: - Lightweight model interface used by the row.
// Adapt this to your real model or make it init from your SwiftData entity.
struct MesocycleItem: Identifiable, Hashable {
    let id: AnyHashable
    let name: String
    let weekCount: Int
    let daysPerWeek: Int
    let status: Mesocycle.Status
    
    // Computed properties for backward compatibility
    var isCurrent: Bool { status == .current }
    var isCompleted: Bool { status == .completed }
}

struct MesocycleRowView: View {
    let item: MesocycleItem

    // Action closures (wire these up in the list view)
    let onNewNote: () -> Void
    let onRename: () -> Void
    let onCopy: () -> Void
    let onSummary: () -> Void
    let onSaveTemplate: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Title + subtitle
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)

                Text("\(item.weekCount) \(item.weekCount == 1 ? "WEEK" : "WEEKS") – \(item.daysPerWeek) \(item.daysPerWeek == 1 ? "DAY" : "DAYS")/WEEK")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            // Status badge
            switch item.status {
            case .current:
                StatusChip(text: "CURRENT", tint: .blue)
                    .transition(.scale.combined(with: .opacity))
                    .accessibilityLabel("Current mesocycle")
            case .completed:
                StatusChip(text: "COMPLETED", tint: .green)
                    .transition(.scale.combined(with: .opacity))
                    .accessibilityLabel("Mesocycle completed")
            case .planned:
                EmptyView()
            }

            // Visible ellipsis menu (discoverable)
            Menu {
                Button("New Note", action: withHaptic(onNewNote))
                Button("Rename", action: withHaptic(onRename))
                Button("Copy Mesocycle", action: withHaptic(onCopy))
                Button("Summary", action: withHaptic(onSummary))
                Button("Save as Template", action: withHaptic(onSaveTemplate))
                Divider()
                Button(role: .destructive) {
                    withHaptic(onDelete)()
                } label: {
                    Label("Delete Mesocycle", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .imageScale(.large)
                    .padding(.horizontal, 8)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("More actions")
        }
        .contentShape(Rectangle()) // full-row tap target
        // Quick actions for power users
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                withHaptic(onDelete)()
            } label: {
                Label("Delete", systemImage: "trash")
            }
            Button("Copy", action: withHaptic(onCopy)).tint(.indigo)
            Button("Rename", action: withHaptic(onRename)).tint(.blue)
        }
        // Optional: long-press context menu mirrors Menu
        .contextMenu {
            Button("New Note", action: withHaptic(onNewNote))
            Button("Rename", action: withHaptic(onRename))
            Button("Copy Mesocycle", action: withHaptic(onCopy))
            Button("Summary", action: withHaptic(onSummary))
            Button("Save as Template", action: withHaptic(onSaveTemplate))
            Divider()
            Button("Delete Mesocycle", role: .destructive) { withHaptic(onDelete)() }
        }
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens mesocycle or shows actions")
    }

    // MARK: - Haptics helper
    private func withHaptic(_ action: @escaping () -> Void) -> () -> Void {
        return {
            #if canImport(UIKit)
            let gen = UIImpactFeedbackGenerator(style: .light)
            gen.impactOccurred()
            #endif
            action()
        }
    }
}

// MARK: - CapsuleLabel (CURRENT pill)
private struct CapsuleLabel: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundStyle(.white)
            .background(.blue, in: Capsule())
    }
}
