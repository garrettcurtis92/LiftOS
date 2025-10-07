//
//  ChatHostOverlay.swift
//  LiftOS
//
//  Created by Garrett Curtis on 9/18/25.
//
import SwiftUI

struct ChatHostOverlay: View {
    @StateObject private var controller = ChatController.shared
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // 1) Floating orb (always available when mode == .orb)
            if controller.mode == .orb {
                ChatLauncherButton(isPresented: .constant(false)) // keep API but not used
                    .environmentObject(controller)
                    .padding(.trailing, 20)
                    .padding(.bottom, 28)
                    .transition(.scale.combined(with: .opacity))
            }

            // 2) Siri-style dock
            if controller.mode == .docked {
                ChatDock()
                    .environmentObject(controller)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .ignoresSafeArea(.keyboard, edges: .bottom)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 10)
            }

            // 3) Expanded panel (uses your existing ChatWindowView)
            if controller.mode == .expanded {
                ChatWindowView()
                    .environmentObject(controller)
                    .transition(.opacity)
            }
        }
        .animation(.snappy, value: controller.mode)
        .accessibilityElement(children: .contain)
    }
}

