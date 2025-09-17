import SwiftUI

struct PrimaryButton: View {
    @Environment(\.colorScheme) private var scheme
    var title: String
    var systemIcon: String? = nil
    var style: PrimaryButtonStyle = .primary
    var action: () -> Void

    var body: some View {
        Button(action: { Haptics.tap(); action() }) {
            Label { Text(title).font(TypeScale.headline()) } icon: { if let systemIcon { Image(systemName: systemIcon) } }
        }
        .labelStyle(.automatic)
        .buttonStyle(.borderedProminent)
        .tint(tintColor)
        .foregroundStyle(scheme == .dark ? Color.black : Color.white)
        .controlSize(.large)
        .accessibilityLabel(Text(title))
    }
    
    private var tintColor: Color {
        switch style {
        case .primary:
            return MulticolorAccent.color(for: .primary)
        case .success:
            return MulticolorAccent.color(for: .success)
        }
    }
}

enum PrimaryButtonStyle {
    case primary
    case success
}

