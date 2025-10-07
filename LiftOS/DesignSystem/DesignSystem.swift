import SwiftUI

enum DS {
    // System Colors
    static var sep: Color { Color(.separator) }
    static var groupBg: Color { Color(.systemGroupedBackground) }
    static var bg: Color { Color(.systemBackground) }
    static var label: Color { Color(.label) }
    static var secondaryLabel: Color { Color(.secondaryLabel) }
    
    // Metrics
    enum Metrics {
        static let cardInset: CGFloat = 16
        static let corner: CGFloat = 14
        static let pill: CGFloat = 28
        static let rowSpacing: CGFloat = 6
    }
    
    // Legacy color roles (keeping for backwards compatibility)
    struct ColorRole { let bg: Color; let surface: Color; let label: Color; let secondaryLabel: Color }
    static var colors: ColorRole { ColorRole(bg: .clear, surface: Color(.secondarySystemBackground), label: .primary, secondaryLabel: .secondary) }
    
    // Legacy spacing/radius (keeping for backwards compatibility)
    enum Space: CGFloat { case xs = 4, sm = 8, md = 12, lg = 16, xl = 24, xxl = 32 }
    enum Radius: CGFloat { case sm = 10, md = 14, lg = 18, xl = 24 }
    struct Shadow { static let card = ShadowStyle(radius: 12, y: 4, opacity: 0.08) }
    struct ShadowStyle { let radius: CGFloat; let y: CGFloat; let opacity: Double }
}

extension View { func dsShadow(_ s: DS.ShadowStyle = DS.Shadow.card) -> some View { shadow(color: .black.opacity(s.opacity), radius: s.radius, x: 0, y: s.y) } }
