//
//  StatusChip.swift
//  LiftOS
//
//  Created by Garrett Curtis on 10/6/25.
//

import SwiftUI

struct StatusChip: View {
    let text: String
    let tint: Color
    
    var body: some View {
        Text(text)
            .font(.callout.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().stroke(tint.opacity(0.35), lineWidth: 1))
            .foregroundStyle(tint)
    }
}

#Preview {
    VStack(spacing: 16) {
        StatusChip(text: "Current", tint: .blue)
        StatusChip(text: "Completed", tint: .green)
        StatusChip(text: "Planned", tint: .orange)
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}
