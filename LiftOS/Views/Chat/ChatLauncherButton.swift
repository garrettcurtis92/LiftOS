//
//  ChatLauncherButton.swift
//  LiftOS
//
//  Created by Garrett Curtis on 9/18/25.
//
import SwiftUI

struct ChatLauncherButton: View {
    @Binding var isPresented: Bool

    var body: some View {
        Button(action: {
            withAnimation(.spring()) {
                isPresented = true
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(Circle())
                .shadow(radius: 8)
        }
        .accessibilityLabel("Chat Assistant")
        .accessibilityHint("Opens the AI chat assistant")
    }
}

