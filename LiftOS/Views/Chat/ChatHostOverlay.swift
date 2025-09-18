//
//  ChatHostOverlay.swift
//  LiftOS
//
//  Created by Garrett Curtis on 9/18/25.
//
import SwiftUI

struct ChatHostOverlay: View {
    @State private var showChat = false

    var body: some View {
        ZStack {
            Spacer() // Placeholder for layout

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    ChatLauncherButton(isPresented: $showChat)
                        .padding(.bottom, 30)
                        .padding(.trailing, 20)
                }
            }
        }
        .sheet(isPresented: $showChat) {
            ChatWindowView()
        }
    }
}

