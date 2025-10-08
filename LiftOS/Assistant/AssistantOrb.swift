//
//  AssistantOrb.swift
//  LiftOS
//
//  Created by GitHub Copilot on 10/1/25.
//

import SwiftUI
import UIKit

struct AssistantOrb: View {
    @EnvironmentObject private var orb: OrbController

    /// The logical name of the tab this overlay sits on (e.g., "train")
    let tabKey: String

    /// Provide selected accent automatically (fallback to accentColor)
    @State private var accentColor: Color = .accentColor

    @State private var dragOffset: CGSize = .zero
    @State private var isPressed: Bool = false
    @State private var isBreathing: Bool = true

    private let baseSize: CGFloat = 58

    var body: some View {
        GeometryReader { proxy in
            if orb.shouldShow(for: tabKey) {
                orbView
                    .position(calcCGPoint(in: proxy.size))
                    .gesture(dragGesture(in: proxy.size))
                    .simultaneousGesture(tapGesture)
                    .simultaneousGesture(longPressGesture)
                    .contextMenu {
                        contextMenuActions
                    }
                    .animation(.snappy(duration: 0.2, extraBounce: 0.0), value: dragOffset)
                    .animation(.snappy(duration: 0.2), value: orb.position(for: tabKey))
                    .accessibilityLabel("Assistant")
                    .accessibilityHint("Double tap to open assistant")
            } else if orb.isDismissedTemporarily && !orb.isHidden {
                // Show a small tab on the right edge
                showAssistantButton
                    .position(x: proxy.size.width - 18, y: proxy.size.height / 2)
            }
        }
        .allowsHitTesting(true) // hit only when shown
    }

    private var orbView: some View {
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)
                .overlay {
                    Circle()
                        .strokeBorder(.secondary.opacity(0.15), lineWidth: 0.5)
                }
                .shadow(color: .black.opacity(0.18), radius: 12, x: 0, y: 8)

            // Siri-like layered pulses
            Circle()
                .inset(by: 8)
                .fill(AngularGradient(gradient: Gradient(colors: [
                    accentColor.opacity(0.9),
                    .blue.opacity(0.85),
                    .purple.opacity(0.85),
                    accentColor.opacity(0.9)
                ]), center: .center))
                .blur(radius: 14)
                .opacity(isBreathing ? 0.55 : 0.35)
                .scaleEffect(isBreathing ? 1.06 : 0.98)
                .animation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true), value: isBreathing)

            Circle()
                .inset(by: 14)
                .fill(.thinMaterial)
                .overlay {
                    Image(systemName: "sparkles")
                        .font(.system(size: 20, weight: .semibold))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.primary.opacity(0.9))
                }
        }
        .frame(width: baseSize, height: baseSize)
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .onAppear { isBreathing = true }
    }
    
    private var showAssistantButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.snappy(duration: 0.25)) {
                orb.isDismissedTemporarily = false
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .semibold))
                Text("AI")
                    .font(.system(size: 9, weight: .medium))
                    .tracking(0.5)
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: .black.opacity(0.08), radius: 4, x: -2, y: 0)
        }
        .buttonStyle(.plain)
        .transition(.move(edge: .trailing).combined(with: .opacity))
        .accessibilityLabel("Show Assistant")
        .accessibilityHint("Tap to show the AI assistant orb")
    }

    // MARK: Gestures

    private var tapGesture: some Gesture {
        TapGesture()
            .onEnded {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                orb.isPresentingSheet = true
            }
    }

    private var longPressGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.35)
            .onChanged { _ in
                guard !isPressed else { return }
                isPressed = true
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            }
            .onEnded { _ in
                isPressed = false
            }
            .simultaneously(with:
                // Context menu - using TapGesture as placeholder for contextMenu
                TapGesture().onEnded {
                    // Context menu will be triggered by long press naturally
                }
            )
    }

    // Context menu via modifier
    private var contextMenuActions: some View {
        Group {
            Button {
                orb.isPresentingSheet = true
            } label: { Label("New Chat", systemImage: "sparkles") }

            Divider()

            Menu("Visibility") {
                Picker("Scope", selection: Binding<OrbScope>(
                    get: { orb.scope }, set: { orb.scope = $0 }
                )) {
                    ForEach(OrbScope.allCases, id: \.self) { scope in
                        Text(scopeLabel(scope)).tag(scope)
                    }
                }
                .pickerStyle(.inline)
            }
            
            Button {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                withAnimation(.snappy(duration: 0.25)) {
                    orb.isDismissedTemporarily = true
                }
            } label: { Label("Dismiss", systemImage: "eye.slash") }
        }
    }

    private func dragGesture(in container: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { value in
                dragOffset = value.translation
            }
            .onEnded { value in
                let current = orb.position(for: tabKey)
                // Convert absolute drag to normalized position
                let pt = calcCGPoint(in: container, pos: current)
                    .applying(CGAffineTransform(translationX: value.translation.width, y: value.translation.height))

                let clampedX = min(max(pt.x, 32), container.width - 32)
                let clampedY = min(max(pt.y, 120), container.height - 120) // keep off tab bar/toolbars

                // snap to nearest side
                let snapSide: OrbSnapSide = (clampedX < container.width/2) ? .leading : .trailing
                let snapX = snapSide == .leading ? 42 : container.width - 42

                let normalized = OrbPosition(
                    x: snapX / container.width,
                    y: clampedY / container.height,
                    side: snapSide
                )
                orb.setPosition(normalized, for: tabKey)
                dragOffset = .zero
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
    }

    // MARK: Helpers

    private func calcCGPoint(in size: CGSize, pos: OrbPosition? = nil) -> CGPoint {
        let p = pos ?? orb.position(for: tabKey)
        let x = p.x * size.width + dragOffset.width
        let y = p.y * size.height + dragOffset.height
        return CGPoint(x: x, y: y)
    }

    private func scopeLabel(_ s: OrbScope) -> String {
        switch s {
        case .global: "Show on All Tabs"
        case .perTab: "Remember Position Per Tab"
        case .trainOnly: "Train Tab Only"
        }
    }
}
