//
//  AppearanceView.swift
//  LiftOS
//
//  Created by Garrett Curtis on 9/17/25.
//

import SwiftUI

struct AppearanceView: View {
    var body: some View {
        Form {
            AccentPickerSection()
        }
        .tint(MulticolorAccent.color(for: .primary))
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Accent Color Models

enum AccentChoice: String, CaseIterable, Identifiable {
    case multicolor = "multicolor"
    case blue = "blue"
    case purple = "purple"
    case pink = "pink"
    case red = "red"
    case orange = "orange"
    case yellow = "yellow"
    case green = "green"
    case graphite = "graphite"
    
    var id: String { rawValue }
    
    var label: String {
        switch self {
        case .multicolor: return "Multicolor"
        case .blue: return "Blue"
        case .purple: return "Purple"
        case .pink: return "Pink"
        case .red: return "Red"
        case .orange: return "Orange"
        case .yellow: return "Yellow"
        case .green: return "Green"
        case .graphite: return "Graphite"
        }
    }
    
    var color: Color {
        switch self {
        case .multicolor: return .blue // Default fallback for multicolor
        case .blue: return .blue
        case .purple: return .purple
        case .pink: return .pink
        case .red: return .red
        case .orange: return .orange
        case .yellow: return .yellow
        case .green: return .green
        case .graphite: return .gray
        }
    }
}

// MARK: - Multicolor System

struct MulticolorAccent {
    @AppStorage("accentChoice") private static var accentChoiceRaw: String = AccentChoice.multicolor.rawValue
    
    static var isMulticolor: Bool {
        let choice = AccentChoice(rawValue: accentChoiceRaw) ?? .multicolor
        return choice == .multicolor
    }
    
    static func color(for context: MulticolorContext) -> Color {
        let choice = AccentChoice(rawValue: accentChoiceRaw) ?? .multicolor
        
        if choice == .multicolor {
            return context.color
        } else {
            return choice.color
        }
    }
}

enum MulticolorContext {
    case calendar
    case success
    case warning
    case destructive
    case primary
    case secondary
    case navigation
    
    var color: Color {
        switch self {
        case .calendar: return .red
        case .success: return .green
        case .warning: return .orange
        case .destructive: return .red
        case .primary: return .blue
        case .secondary: return .purple
        case .navigation: return .blue
        }
    }
}

// MARK: - Accent Picker Section

struct AccentPickerSection: View {
    @AppStorage("accentChoice") private var accentChoiceRaw: String = AccentChoice.multicolor.rawValue

    private var selected: AccentChoice {
        AccentChoice(rawValue: accentChoiceRaw) ?? .multicolor
    }
    
    private func setSelected(_ choice: AccentChoice) {
        accentChoiceRaw = choice.rawValue
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }

    // 3-column grid for better layout
    private let cols = Array(repeating: GridItem(.flexible(minimum: 44), spacing: 16), count: 3)

    var body: some View {
        Section("Accent Color") {
            LazyVGrid(columns: cols, alignment: .center, spacing: 16) {
                ForEach(AccentChoice.allCases) { choice in
                    AccentChip(choice: choice, isSelected: choice == selected)
                        .onTapGesture { setSelected(choice) }
                        .accessibilityLabel(choice.label)
                        .accessibilityAddTraits(choice == selected ? .isSelected : [])
                }
            }
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Accent Chip

private struct AccentChip: View {
    let choice: AccentChoice
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(fill)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Circle()
                            .strokeBorder(isSelected ? Color.primary.opacity(0.45) : Color.secondary.opacity(0.2), lineWidth: 2)
                    )
                
                if choice == .multicolor {
                    // Special multicolor indicator
                    HStack(spacing: 1) {
                        Circle().fill(.red).frame(width: 8, height: 8)
                        Circle().fill(.green).frame(width: 8, height: 8)
                        Circle().fill(.blue).frame(width: 8, height: 8)
                    }
                }
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(choice == .multicolor ? .white : .white)
                        .shadow(radius: 1)
                }
            }
            
            Text(choice.label)
                .font(.caption)
                .foregroundStyle(isSelected ? .primary : .secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var fill: AnyShapeStyle {
        choice == .multicolor ? AnyShapeStyle(.thinMaterial) : AnyShapeStyle(choice.color)
    }
}
#Preview{
    AppearanceView()
}
