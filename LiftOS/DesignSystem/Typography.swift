import SwiftUI

/// Legacy TypeScale - kept for backwards compatibility
/// New code should use FitnessDS.Typography from Theme.swift
enum TypeScale { 
    static func title(_ w: Font.Weight = .bold) -> Font { .title2.weight(w) }
    static func headline(_ w: Font.Weight = .semibold) -> Font { .headline.weight(w) }
    static func body(_ w: Font.Weight = .regular) -> Font { .body.weight(w) }
    static func subheadline(_ w: Font.Weight = .regular) -> Font { .subheadline.weight(w) }
    static func footnote(_ w: Font.Weight = .regular) -> Font { .footnote.weight(w) }
}

// MARK: - View Extensions for Typography

extension View {
    /// Apply display typography (large titles, hero text)
    func displayText(_ size: DisplaySize = .medium) -> some View {
        switch size {
        case .large:
            return self.font(FitnessDS.Typography.displayLarge)
        case .medium:
            return self.font(FitnessDS.Typography.displayMedium)
        case .small:
            return self.font(FitnessDS.Typography.displaySmall)
        }
    }
    
    /// Apply headline typography with proper Dynamic Type scaling
    func headlineText(_ size: HeadlineSize = .medium) -> some View {
        switch size {
        case .large:
            return self.font(FitnessDS.Typography.headlineLarge)
        case .medium:
            return self.font(FitnessDS.Typography.headlineMedium)
        case .small:
            return self.font(FitnessDS.Typography.headlineSmall)
        }
    }
    
    /// Apply body typography with proper Dynamic Type scaling
    func bodyText(_ size: BodySize = .medium) -> some View {
        switch size {
        case .large:
            return self.font(FitnessDS.Typography.bodyLarge)
        case .medium:
            return self.font(FitnessDS.Typography.bodyMedium)
        case .small:
            return self.font(FitnessDS.Typography.bodySmall)
        }
    }
    
    /// Apply numeric typography (automatically monospaced)
    func numericText(_ size: NumericSize = .medium) -> some View {
        let font: Font
        switch size {
        case .large:
            font = FitnessDS.Typography.numericLarge
        case .medium:
            font = FitnessDS.Typography.numericMedium
        case .small:
            font = FitnessDS.Typography.numericSmall
        case .caption:
            font = FitnessDS.Typography.numericCaption
        }
        
        return self
            .font(font)
            .numericTextTransitionIfAvailable()
    }
}

// MARK: - Typography Size Enums

enum DisplaySize {
    case large, medium, small
}

enum HeadlineSize {
    case large, medium, small
}

enum BodySize {
    case large, medium, small
}

enum NumericSize {
    case large, medium, small, caption
}
