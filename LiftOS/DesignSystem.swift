//
//  DesignSystem.swift
//  LiftOS
//
//  Created by Garrett Curtis on 9/13/25.
//
import SwiftUI

enum DS {
    struct ColorRole {
        let bg: Color            // often clear because we use gradient/materials
        let surface: Color       // cards/panels
        let label: Color         // primary text
        let secondaryLabel: Color
    }
    static var colors: ColorRole {
        ColorRole(
            bg: .clear,
            surface: Color(.secondarySystemBackground),
            label: .primary,
            secondaryLabel: .secondary
        )
    }

    enum Space: CGFloat { case xs = 4, sm = 8, md = 12, lg = 16, xl = 24, xxl = 32 }
    enum Radius: CGFloat { case sm = 10, md = 14, lg = 18, xl = 24 }

    struct Shadow {
        static let card = ShadowStyle(radius: 12, y: 4, opacity: 0.08)
    }
    struct ShadowStyle { let radius: CGFloat; let y: CGFloat; let opacity: Double }
}

extension View {
    func dsShadow(_ s: DS.ShadowStyle = DS.Shadow.card) -> some View {
        shadow(color: .black.opacity(s.opacity), radius: s.radius, x: 0, y: s.y)
    }
}
