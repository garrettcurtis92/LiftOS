//
//  AssistantSheetView.swift
//  LiftOS
//
//  Created by GitHub Copilot on 10/1/25.
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

struct AssistantSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme

    @State private var query: String = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Handle
            Capsule()
                .fill(.secondary.opacity(0.35))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 6)
                .accessibilityHidden(true)

            // Header
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.system(size: 20, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                Text("LiftOS Assistant")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                Spacer(minLength: 0)
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close")
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)

            // Conversation list placeholder (to be replaced by your chat)
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("How can I help with your workout?")
                        .font(.title3.weight(.semibold))
                        .padding(.top, 8)
                    Text("Ask about form cues, rep targets, or modify your session hands-free.")
                        .foregroundStyle(.secondary)
                    
                    // Quick suggestions
                    VStack(spacing: 8) {
                        suggestionButton("💪 How many sets should I do?")
                        suggestionButton("📊 Show my progress on bench press")
                        suggestionButton("⏱️ What's my rest timer set to?")
                        suggestionButton("🔄 Suggest a progression for squats")
                    }
                    .padding(.top, 12)
                }
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Input bar
            HStack(spacing: 10) {
                TextField("Ask something…", text: $query, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...4)
                    .submitLabel(.send)
                    .focused($isInputFocused)
                    .onSubmit {
                        sendQuery()
                    }
                Button {
                    sendQuery()
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 16, weight: .semibold))
                }
                .buttonStyle(.borderedProminent)
                .disabled(query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.thinMaterial)
        }
        .background(background)
        .presentationCornerRadius(28)
        .presentationDragIndicator(.hidden) // we have a custom handle
        .interactiveDismissDisabled(false)
        .toolbar(.hidden, for: .navigationBar) // keep it Siri-clean
        .onAppear {
            // Auto-focus input after a slight delay for smooth presentation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isInputFocused = true
            }
        }
    }

    // MARK: - Subviews
    
    private func suggestionButton(_ text: String) -> some View {
        Button {
            query = text
            isInputFocused = true
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    private var background: some View {
        // Siri-adjacent: blurred with soft gradient tint
        ZStack {
            Rectangle().fill(scheme == .dark ? Color.black : Color(UIColor.systemBackground))
            LinearGradient(colors: [
                .blue.opacity(0.12),
                .purple.opacity(0.10),
                .clear
            ], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
        .ignoresSafeArea()
        .opacity(0.98)
    }
    
    // MARK: - Actions
    
    private func sendQuery() {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        
        // TODO: Hook to your chat pipeline/backend here
        // For now, just clear the input
        query = ""
        
        // Could add:
        // - Send to OpenAI/Claude API
        // - Add to conversation history
        // - Show typing indicator
        // - Handle responses
    }
}

#Preview {
    AssistantSheetView()
}
