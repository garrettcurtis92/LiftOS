//
//  ChatDock.swift
//  LiftOS
//
//  Created by Garrett Curtis on 10/2/25.
//

import SwiftUI

struct ChatDock: View {
    @EnvironmentObject private var controller: ChatController
    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: 10) {
            // leading glyph
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.thinMaterial)
                Image(systemName: controller.isThinking ? "ellipsis" : "sparkles")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
            }
            .frame(width: 32, height: 32)

            // text field
            TextField("Ask LiftOS…", text: $controller.draft, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.body)
                .lineLimit(1...3)
                .focused($focused)

            // actions
            HStack(spacing: 6) {
                if controller.draft.isEmpty {
                    Button {
                        // mic or quick action later
                    } label: { Image(systemName: "mic") }
                    .buttonStyle(.borderless)
                } else {
                    Button {
                        send()
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .symbolRenderingMode(.hierarchical)
                    }
                    .buttonStyle(.borderedProminent)
                    .clipShape(Capsule())
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            Capsule(style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule().strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.12), radius: 20, y: 8)
        )
        .onAppear { focused = true }
        .onSubmit { send() }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .accessibilityElement(children: .contain)
    }

    private func send() {
        let trimmed = controller.draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        controller.isThinking = true
        controller.tapHaptic()
        // TODO: route to your chat pipeline
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            controller.isThinking = false
            controller.draft = ""
            controller.successHaptic()
        }
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.2).ignoresSafeArea()
        
        VStack {
            Spacer()
            ChatDock()
                .environmentObject(ChatController.shared)
                .padding(.horizontal, 12)
                .padding(.bottom, 10)
        }
    }
}
