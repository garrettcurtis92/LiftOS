import SwiftUI

struct GlassPanel<Content: View>: View {
    let content: () -> Content
    init(@ViewBuilder content: @escaping () -> Content) { self.content = content }
    var body: some View {
        content()
            .padding(DS.Space.lg.rawValue)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DS.Radius.lg.rawValue, style: .continuous))
            .overlay { RoundedRectangle(cornerRadius: DS.Radius.lg.rawValue, style: .continuous).strokeBorder(Color.white.opacity(0.08)) }
            .dsShadow()
    }
}

extension View { func glassBackground() -> some View { self.background(LinearGradient(colors: [Color.black.opacity(0.30), Color.black.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()) } }
