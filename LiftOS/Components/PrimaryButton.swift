import SwiftUI

struct PrimaryButton: View {
    var title: String
    var systemIcon: String? = nil
    var action: () -> Void

    var body: some View {
        Button(action: { Haptics.tap(); action() }) {
            Label { Text(title).font(TypeScale.headline()) } icon: { if let systemIcon { Image(systemName: systemIcon) } }
        }
        .labelStyle(.automatic)
        .buttonStyle(.borderedProminent)
        .tint(.accentColor)
        .foregroundStyle(.white)
        .controlSize(.large)
        .accessibilityLabel(Text(title))
    }
}
