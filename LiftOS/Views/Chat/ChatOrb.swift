import SwiftUI
import Combine
import UIKit

/// Floating chat assistant orb - Siri/Copilot inspired
/// Stays in bottom-right corner, context-aware (hides for keyboard, fades when scrolling)
struct ChatOrb: View {
    @State private var listening = false
    @State private var pulse = false
    @State private var orbHidden = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            // Accent glow pulse (when active)
            if listening {
                Circle()
                    .fill(Color.accentColor.opacity(0.25))
                    .frame(width: 60, height: 60)
                    .scaleEffect(pulse ? 1.2 : 0.9)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulse)
            }
            
            // Main orb with material background
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 52, height: 52)
                .overlay {
                    Image(systemName: listening ? "waveform" : "ellipsis.bubble.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(Color.accentColor)
                        .symbolEffect(.variableColor.iterative, isActive: listening)
                }
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.4 : 0.15), radius: 6, y: 2)
                .overlay {
                    Circle()
                        .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
                }
        }
        .opacity(orbHidden ? 0 : 1)
        .scaleEffect(orbHidden ? 0.8 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: orbHidden)
        .onAppear {
            pulse = true
        }
        // Note: Tap gesture handled by parent (ContentView) to open chat sheet
        // Keyboard avoidance
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            withAnimation(.easeOut(duration: 0.25)) {
                orbHidden = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.easeIn(duration: 0.25)) {
                orbHidden = false
            }
        }
    }
}

/// Floating orb container with context-aware behavior
struct ChatOrbContainer: View {
    @State private var isVisible = true
    @State private var offset: CGFloat = 0
    @FocusState private var keyboardVisible: Bool
    
    // Hide when keyboard is up
    @Environment(\.keyboardHeight) private var keyboardHeight
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    ChatOrb()
                        .opacity(isVisible ? 1 : 0.3)
                        .scaleEffect(isVisible ? 1 : 0.8)
                        .offset(y: offset)
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isVisible)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: offset)
        }
        .ignoresSafeArea(.keyboard)
        .onChange(of: keyboardHeight) { oldValue, newValue in
            // Move up when keyboard appears
            if newValue > 0 {
                offset = -newValue - 20
                isVisible = false
            } else {
                offset = 0
                isVisible = true
            }
        }
    }
}

// MARK: - Keyboard Height Environment Key

private struct KeyboardHeightKey: EnvironmentKey {
    static let defaultValue: CGFloat = 0
}

extension EnvironmentValues {
    var keyboardHeight: CGFloat {
        get { self[KeyboardHeightKey.self] }
        set { self[KeyboardHeightKey.self] = newValue }
    }
}

// MARK: - Preview

#Preview("Chat Orb") {
    ZStack {
        Color.gray.opacity(0.1).ignoresSafeArea()
        VStack {
            Spacer()
            HStack {
                Spacer()
                ChatOrb()
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
            }
        }
    }
}

#Preview("Chat Orb - Dark Mode") {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack {
            Spacer()
            HStack {
                Spacer()
                ChatOrb()
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
            }
        }
    }
    .preferredColorScheme(.dark)
}
