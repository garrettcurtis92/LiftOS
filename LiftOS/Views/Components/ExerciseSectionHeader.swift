import SwiftUI

/// LANDMINE ROW — BARBELL style header
struct ExerciseSectionHeader: View {
    let primary: String
    var secondary: String? = nil

    var body: some View {
        HStack(spacing: 8) {
            Text(primary)
                .font(.footnote.weight(.semibold))
                .textCase(.uppercase)
                .foregroundStyle(.primary)
                .opacity(0.9)
            if let secondary {
                Text("—")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(secondary)
                    .font(.footnote.weight(.semibold))
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 2)
        .padding(.bottom, 2)
    }
}

extension View {
    /// Convenience to apply a header in Section
    func exerciseHeader(_ primary: String, _ secondary: String? = nil) -> some View { self
        .modifier(_ExerciseHeaderModifier(primary: primary, secondary: secondary))
    }
}

private struct _ExerciseHeaderModifier: ViewModifier {
    let primary: String
    let secondary: String?
    func body(content: Content) -> some View {
        Section {
            content
        } header: {
            ExerciseSectionHeader(primary: primary, secondary: secondary)
        }
    }
}