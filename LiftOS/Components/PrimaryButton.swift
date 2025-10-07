import SwiftUI

// MARK: - Primary Button (Enhanced)

struct PrimaryButton: View {
    var title: String
    var systemIcon: String? = nil
    var style: PrimaryButtonStyle = .primary
    var size: ButtonSize = .large
    var expands: Bool = true
    var action: () -> Void
    
    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true

    var body: some View {
        Button(action: {
            if hapticsEnabled { Haptics.tap() }
            action()
        }) {
            if let systemIcon {
                Label {
                    Text(title).font(.headline)
                } icon: {
                    Image(systemName: systemIcon)
                }
            } else {
                Text(title).font(.headline)
            }
        }
        .frame(maxWidth: expands ? .infinity : nil)
        .buttonStyle(.borderedProminent)
        .tint(backgroundColor) // FitnessDS.FitnessTint.*
        .controlSize(controlSize) // maps to small/regular/large
        .accessibilityLabel(Text(title))
    }
    
    private var controlSize: ControlSize {
        switch size {
        case .small:  return .small
        case .medium: return .regular
        case .large:  return .large
        }
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary: return FitnessDS.FitnessTint.primary
        case .success: return FitnessDS.FitnessTint.success
        case .warning: return FitnessDS.FitnessTint.warning
        case .destructive: return FitnessDS.FitnessTint.danger
        }
    }
}

// MARK: - Tonal Button (New)

struct TonalButton: View {
    var title: String
    var systemIcon: String? = nil
    var style: TonalButtonStyle = .neutral
    var size: ButtonSize = .medium
    var action: () -> Void
    
    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true

    var body: some View {
        Button(action: { 
            if hapticsEnabled { Haptics.tap() }
            action() 
        }) {
            HStack(spacing: FitnessDS.Space.sm.rawValue) {
                if let systemIcon {
                    Image(systemName: systemIcon)
                        .imageScale(iconScale)
                }
                Text(title)
                    .font(buttonFont)
                    .fontWeight(.medium)
            }
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(FitnessDS.Materials.surface, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(title))
    }
    
    private var foregroundColor: Color {
        switch style {
        case .neutral:
            return .primary
        case .accent:
            return FitnessDS.FitnessTint.primary
        case .success:
            return FitnessDS.FitnessTint.success
        case .warning:
            return FitnessDS.FitnessTint.warning
        }
    }
    
    private var buttonFont: Font {
        switch size {
        case .small:
            return FitnessDS.Typography.captionLarge
        case .medium:
            return FitnessDS.Typography.bodySmall
        case .large:
            return FitnessDS.Typography.bodyMedium
        }
    }
    
    private var iconScale: Image.Scale {
        switch size {
        case .small:
            return .small
        case .medium:
            return .medium
        case .large:
            return .large
        }
    }
    
    private var horizontalPadding: CGFloat {
        switch size {
        case .small:
            return FitnessDS.Space.sm.rawValue
        case .medium:
            return FitnessDS.Space.md.rawValue
        case .large:
            return FitnessDS.Space.lg.rawValue
        }
    }
    
    private var verticalPadding: CGFloat {
        switch size {
        case .small:
            return FitnessDS.Space.xs.rawValue
        case .medium:
            return FitnessDS.Space.sm.rawValue
        case .large:
            return FitnessDS.Space.md.rawValue
        }
    }
}

// MARK: - Enums

enum PrimaryButtonStyle {
    case primary
    case success
    case warning
    case destructive
}

enum TonalButtonStyle {
    case neutral
    case accent
    case success
    case warning
}

enum ButtonSize {
    case small
    case medium
    case large
}

// MARK: - Previews

#Preview("Primary Buttons") {
    VStack(spacing: FitnessDS.Space.lg.rawValue) {
        PrimaryButton(title: "Primary", systemIcon: "checkmark.circle", style: .primary) {}
        PrimaryButton(title: "Success", systemIcon: "checkmark", style: .success) {}
        PrimaryButton(title: "Warning", systemIcon: "exclamationmark.triangle", style: .warning) {}
        PrimaryButton(title: "Destructive", systemIcon: "trash", style: .destructive) {}
    }
    .padding()
    .background(Color.black)
}

#Preview("Tonal Buttons") {
    VStack(spacing: FitnessDS.Space.md.rawValue) {
        HStack(spacing: FitnessDS.Space.md.rawValue) {
            TonalButton(title: "Neutral", size: .small) {}
            TonalButton(title: "Accent", style: .accent, size: .small) {}
        }
        
        HStack(spacing: FitnessDS.Space.md.rawValue) {
            TonalButton(title: "Medium", systemIcon: "timer") {}
            TonalButton(title: "Success", systemIcon: "checkmark", style: .success) {}
        }
        
        TonalButton(title: "Large Button", systemIcon: "star.fill", size: .large) {}
    }
    .padding()
    .background(Color.black)
}

