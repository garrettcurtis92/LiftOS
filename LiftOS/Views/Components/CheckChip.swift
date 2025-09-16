import SwiftUI

/// Apple-polished check control used in inline set rows
struct CheckChip: View {
    @Binding var isOn: Bool
    var action: (() -> Void)? = nil

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                isOn.toggle()
            }
            action?()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: isOn ? "checkmark" : "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .transition(.scale.combined(with: .opacity))
                Text(isOn ? "Done" : "Set")
                    .font(.caption.weight(.semibold))
                    .textCase(.uppercase)
                    .tracking(0.6)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                Capsule(style: .continuous)
                    .strokeBorder(isOn ? Color.accentColor.opacity(0.6) : Color.secondary.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isOn ? "Mark set incomplete" : "Mark set complete")
    }
}