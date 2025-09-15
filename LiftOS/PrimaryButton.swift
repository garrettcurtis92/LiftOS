//
//  PrimaryButton.swift
//  LiftOS
//
//  Created by Garrett Curtis on 9/13/25.
//
import SwiftUI

struct PrimaryButton: View {
    var title: String
    var systemIcon: String? = nil
    var action: () -> Void

    var body: some View {
        Button(action: {
            Haptics.tap()
            action()
        }) {
            Label {
                Text(title).font(TypeScale.headline())
            } icon: {
                if let systemIcon { Image(systemName: systemIcon) }
            }
        }
        .labelStyle(.automatic)
        .buttonStyle(.borderedProminent)   // native + accessible
        .tint(.accentColor)                // system accent; can set AccentColor in Assets later
        .foregroundStyle(.white)           // Ensure text is always white on colored background
        .controlSize(.large)
        .accessibilityLabel(Text(title))
    }
}
