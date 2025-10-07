import SwiftUI

struct DSCard<Content: View>: View {
    var content: () -> Content
    var body: some View {
        content()
            .padding(16)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: DS.Metrics.corner, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: DS.Metrics.corner, style: .continuous)
                    .stroke(DS.sep.opacity(0.5))
            }
    }
}

struct DSPill: View {
    var text: String
    var tint: Color = .accentColor
    var body: some View {
        Text(text)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10).frame(height: DS.Metrics.pill)
            .background(tint, in: Capsule())
            .accessibilityLabel(text)
    }
}

extension View {
    func cardRowPadding() -> some View {
        self.padding(.horizontal, DS.Metrics.cardInset)
            .padding(.vertical, DS.Metrics.rowSpacing)
    }
}
