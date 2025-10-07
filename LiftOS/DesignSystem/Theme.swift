import SwiftUI

// MARK: - Design System

struct FitnessDS {
    /// Spacing tokens for consistent Apple 4/8pt grid layout
    /// All values align with Apple's design system spacing standards
    enum Space: CGFloat, CaseIterable {
        case xs = 4      // Extra small - minimal spacing
        case sm = 8      // Small - tight spacing
        case md = 12     // Medium - comfortable spacing  
        case lg = 16     // Large - generous spacing
        case xl = 24     // Extra large - section spacing
        case xxl = 32    // Extra extra large - major spacing
        
        /// Semantic spacing tokens for workout UI
        static let interSet: CGFloat = 12           // Between set rows within an exercise
        static let interControls: CGFloat = 8       // Between related controls/buttons
        static let interExercise: CGFloat = 12      // Between exercise sections
    }
    
    /// Corner radius tokens - Apple-native values for authentic iOS feel
    /// Rounded rectangles with 10-14pt feel native per Apple guidelines
    enum Corners {
        static let small: CGFloat = 8      // Small components, tight radii
        static let medium: CGFloat = 12    // Standard buttons, cards
        static let large: CGFloat = 16     // Larger cards, panels
        static let button: CGFloat = 12    // Button corner radius
        
        // Legacy support (mapped to new values)
        static let card: CGFloat = medium  // Maps to 12pt for native feel
        static let pill: CGFloat = 100     // Unchanged for pills/capsules
    }
    
    /// Shadow definitions - Minimal shadows following Apple's design philosophy
    /// Let materials and contrast do the work instead of heavy drop shadows
    enum Shadows {
        /// Shadow style structure for modern, minimal shadow API
        struct ShadowStyle {
            public let radius: CGFloat
            public let y: CGFloat
            public let opacity: Double
            
            public init(radius: CGFloat, y: CGFloat, opacity: Double) {
                self.radius = radius
                self.y = y
                self.opacity = opacity
            }
        }
        
        /// Modern minimal shadow (use this for new code)
        static let modernButtonShadow = ShadowStyle(radius: 0, y: 0, opacity: 0)
        
        // Minimal/disabled shadows - rely on materials instead
        static let buttonShadow = FitnessShadow(
            color: Color.clear,  // Disabled shadow
            radius: 0,
            x: 0,
            y: 0
        )
        
        // Legacy FitnessShadow support (converted to minimal shadows)
        static let cardShadow = FitnessShadow(
            color: Color.clear,  // Invisible shadow
            radius: 0,
            x: 0,
            y: 0
        )
        
        // Legacy color support (kept for backwards compatibility but unused)
        static let soft = Color.clear
        static let medium = Color.clear
        static let strong = Color.clear
    }
    
    /// Material definitions for glass/blur components with automatic vibrancy
    /// Uses Apple's thin/ultraThin materials for authentic iOS feel
    enum Materials {
        static var bar: Material { .thin }        // Navigation bars, toolbars
        static var card: Material { .ultraThin }  // Cards, panels with glass effect
        
        // Additional material options
        static var surface: Material { .thin }    // General surfaces
        static var overlay: Material { .ultraThin } // Overlays, sheets
        static var navigation: Material { .ultraThin } // Navigation backgrounds
    }
    
    /// Convenience alias for Materials (use FitnessDS.FitnessMaterial or FitnessDS.Materials)
    typealias FitnessMaterial = Materials
    
    // MARK: - Colors and Materials
    public enum FitnessTint {
        public static var primary: Color { Color.accentColor } // follows app tint in Settings
        public static var success: Color { Color.green }
        public static var warning: Color { Color.orange }
        public static var danger: Color { Color.red }
        
        static func forKey(_ key: String) -> Color {
            let normalizedKey = key.lowercased()
            
            // Exercise type color mapping
            if normalizedKey.contains("barbell") || 
               normalizedKey.contains("squat") || 
               normalizedKey.contains("deadlift") || 
               normalizedKey.contains("bench") || 
               normalizedKey.contains("row") || 
               normalizedKey.contains("press") {
                return .purple
            } else if normalizedKey.contains("machine") {
                return .blue
            } else if normalizedKey.contains("cable") || 
                      normalizedKey.contains("pulldown") {
                return .orange
            } else if normalizedKey.contains("dumbbell") || 
                      normalizedKey.contains(" db ") {
                return .green
            } else if normalizedKey.contains("smith") {
                return .yellow
            } else if normalizedKey.contains("assist") || 
                      normalizedKey.contains("bodyweight") {
                return .mint
            } else {
                return .accentColor
            }
        }
        
        // Legacy aliases for backward compatibility
        static let secondary = Color.indigo
        static let error = Color.red
        static let neutral = Color.gray
    }

    public enum FitnessFill {
        public static var elevated: Color { .primary.opacity(0.05) }
        public static var base: Color { .clear }
        public static var grouped: Color { .gray.opacity(0.1) }
        public static var secondaryGrouped: Color { .gray.opacity(0.05) }
        public static var tertiaryGrouped: Color { .gray.opacity(0.03) }
    }

    public enum FitnessText {
        public static var primary: Color { .primary }
        public static var secondary: Color { .secondary }
        public static var tertiary: Color { .primary.opacity(0.6) }
        public static var quaternary: Color { .primary.opacity(0.4) }
    }

    public enum FitnessStroke {
        public static var hairline: Color { .primary.opacity(0.2) }
        public static var subtle: Color { .primary.opacity(0.3) }
    }
    
    /// Typography system - Apple's semantic text styles
    /// Provides Dynamic Type support and automatic optical adjustments
    enum Typography {
        // MARK: - Apple Semantic Text Styles
        static var largeTitle: Font { .largeTitle }      // navigation title
        static var title1: Font { .title }               // section headline
        static var title2: Font { .title2 }
        static var title3: Font { .title3 }
        static var headline: Font { .headline }
        static var subheadline: Font { .subheadline }
        static var body: Font { .body }
        static var callout: Font { .callout }
        static var footnote: Font { .footnote }
        static var caption: Font { .caption }
        
        // MARK: - Legacy Support (maintained for backwards compatibility)
        static let displayLarge = Font.largeTitle        // maps to largeTitle
        static let displayMedium = Font.title            // maps to title1
        static let displaySmall = Font.title2           // maps to title2
        
        static let headlineLarge = Font.headline        // maps to headline
        static let headlineMedium = Font.headline       // maps to headline
        static let headlineSmall = Font.subheadline     // maps to subheadline
        
        static let bodyLarge = Font.body               // maps to body
        static let bodyMedium = Font.body              // maps to body
        static let bodySmall = Font.callout            // maps to callout
        
        static let captionLarge = Font.caption         // maps to caption
        static let captionMedium = Font.caption        // maps to caption
        static let captionSmall = Font.caption         // maps to caption (caption2 deprecated)
        
        // MARK: - Numeric fonts with monospaced digits
        static let numericLarge = Font.title.monospacedDigit()
        static let numericMedium = Font.headline.monospacedDigit()
        static let numericSmall = Font.body.monospacedDigit()
        static let numericCaption = Font.caption.monospacedDigit()
    }
    
    // MARK: - Typography Convenience Alias
    /// Use FitnessDS.Text instead of FitnessDS.Typography for cleaner syntax
    /// Example: .font(FitnessDS.Text.largeTitle)
    typealias Text = Typography
    
    /// Animation presets
    enum Animations {
        static let quickSpring = Animation.spring(response: 0.3, dampingFraction: 0.7)
        static let smoothSpring = Animation.spring(response: 0.5, dampingFraction: 0.8)
        static let gentleSpring = Animation.spring(response: 0.7, dampingFraction: 0.9)
        
        static let quickEase = Animation.easeInOut(duration: 0.2)
        static let mediumEase = Animation.easeInOut(duration: 0.3)
        static let slowEase = Animation.easeInOut(duration: 0.5)
    }
}

// MARK: - Shadow Helper

struct FitnessShadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Adaptive Background Components

struct AdaptiveGradientBackground: View {
    let accentColor: Color
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        LinearGradient(
            colors: gradientColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var gradientColors: [Color] {
        switch colorScheme {
        case .dark:
            return [
                Color.black,
                accentColor.opacity(0.1),
                Color.black
            ]
        case .light:
            return [
                Color.white,
                accentColor.opacity(0.05),
                Color(white: 0.95)
            ]
        @unknown default:
            return [
                Color.black,
                accentColor.opacity(0.1),
                Color.black
            ]
        }
    }
}

// MARK: - View Extensions for Design System

extension View {
    /// Apply design system shadow
    func fitnessShadow(_ shadow: FitnessShadow) -> some View {
        self.shadow(
            color: shadow.color,
            radius: shadow.radius,
            x: shadow.x,
            y: shadow.y
        )
    }
    
    /// Apply design system card styling
    func fitnessCardStyle() -> some View {
        self
            .background(FitnessDS.Materials.card, in: RoundedRectangle(cornerRadius: FitnessDS.Corners.card))
            .fitnessShadow(FitnessDS.Shadows.cardShadow)
    }
    
    /// Apply design system button styling
    func fitnessButtonStyle(background: Material = FitnessDS.Materials.surface) -> some View {
        self
            .background(background, in: RoundedRectangle(cornerRadius: FitnessDS.Corners.button))
            .fitnessShadow(FitnessDS.Shadows.buttonShadow)
    }
    
    /// Apply design system pill styling
    func fitnessPillStyle(background: Material = FitnessDS.Materials.surface) -> some View {
        self
            .background(background, in: Capsule())
    }
    
    /// Apply fitness-themed background gradient
    func fitnessGradientBackground(for exerciseType: String? = nil) -> some View {
        let baseColor = exerciseType != nil ? FitnessDS.FitnessTint.forKey(exerciseType!) : FitnessDS.FitnessTint.neutral
        
        return self.background(
            AdaptiveGradientBackground(accentColor: baseColor)
        )
    }
    
    /// Apply standard navigation styling
    func dsNavigationStyle() -> some View {
        self
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(FitnessDS.Materials.navigation, for: .navigationBar)
    }
    
    /// Apply fitness app navigation style with enhanced materials
    func fitnessNavigationStyle() -> some View {
        self
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.ultraThinMaterial, for: .tabBar)
    }
}

// MARK: - Color Extensions

extension Color {
    /// Create color from exercise type
    static func fromExerciseType(_ type: String) -> Color {
        return FitnessDS.FitnessTint.forKey(type)
    }
}