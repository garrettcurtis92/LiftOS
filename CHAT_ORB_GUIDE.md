# ChatOrb Integration Guide

## Overview
A beautiful floating assistant orb inspired by Siri and Copilot, designed with Apple's principles of subtlety and context-awareness.

## Features

### Visual Design
- **Idle State**: Shows `ellipsis.bubble.fill` icon in accent color
- **Active State**: Shows animated `waveform` with pulsing glow
- **Material**: Ultra-thin material background for depth
- **Shadow**: Adaptive shadow (lighter in light mode, darker in dark mode)
- **Pulse Animation**: Smooth 1.2s ease-in-out pulse when active

### Context-Aware Behavior
- **Keyboard Detection**: Automatically hides/moves when keyboard appears
- **Scroll Awareness**: Fades opacity when user is scrolling
- **Position**: Bottom-right corner with 20pt padding
- **Spring Animation**: Smooth, bouncy transitions

## Usage

### Basic Integration (Simple)

Add the orb to any view:

```swift
ZStack {
    // Your main content
    YourContentView()
    
    // Floating orb (always on top)
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
```

### Advanced Integration (Context-Aware)

Use `ChatOrbContainer` for automatic keyboard handling:

```swift
ZStack {
    // Your main content
    YourContentView()
    
    // Floating orb with context awareness
    ChatOrbContainer()
}
```

### Full Screen Integration

Add to your workout session view:

```swift
struct WorkoutSessionView: View {
    var body: some View {
        ZStack {
            // Main content
            List { ... }
            
            // Chat orb overlay
            ChatOrbContainer()
        }
    }
}
```

## Customization

### Change Position

```swift
// Top-right corner
VStack {
    HStack {
        Spacer()
        ChatOrb()
            .padding(.trailing, 20)
            .padding(.top, 20)
    }
    Spacer()
}

// Bottom-left corner
VStack {
    Spacer()
    HStack {
        ChatOrb()
            .padding(.leading, 20)
            .padding(.bottom, 20)
        Spacer()
    }
}
```

### Handle Tap Events

```swift
struct MyView: View {
    @State private var showChat = false
    
    var body: some View {
        ZStack {
            YourContent()
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    ChatOrb()
                        .onTapGesture {
                            showChat.toggle()
                        }
                }
            }
        }
        .sheet(isPresented: $showChat) {
            ChatView()
        }
    }
}
```

### Keyboard Height Tracking

For custom keyboard-aware behavior, implement keyboard height tracking:

```swift
import Combine

class KeyboardObserver: ObservableObject {
    @Published var keyboardHeight: CGFloat = 0
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .merge(with: NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification))
            .compactMap { notification -> CGFloat? in
                if notification.name == UIResponder.keyboardWillHideNotification {
                    return 0
                }
                return (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height
            }
            .sink { [weak self] height in
                withAnimation(.spring(response: 0.3)) {
                    self?.keyboardHeight = height
                }
            }
            .store(in: &cancellables)
    }
}
```

## Design Specifications

### Dimensions
- **Outer Glow**: 60x60pt (when active)
- **Main Orb**: 52x52pt
- **Icon Size**: 22pt system font, semibold weight

### Spacing
- **Trailing**: 20pt from screen edge
- **Bottom**: 20pt from screen edge
- **Safe Area**: Respects safe area by default

### Colors
- **Icon**: `.accentColor`
- **Glow**: `.accentColor.opacity(0.25)`
- **Material**: `.ultraThinMaterial`
- **Border**: `.primary.opacity(0.08)` at 0.5pt

### Animations
- **Tap Response**: Spring(response: 0.4, dampingFraction: 0.7)
- **Pulse**: EaseInOut(duration: 1.2, repeating forever)
- **Keyboard**: Spring(response: 0.4, dampingFraction: 0.8)
- **Scale Active**: 1.0 → 0.8 when hidden

### Shadow
- **Light Mode**: `.black.opacity(0.15)`, radius: 6, y: 2
- **Dark Mode**: `.black.opacity(0.4)`, radius: 6, y: 2

## Best Practices

1. **One Per Screen**: Only show one orb at a time
2. **Consistent Position**: Keep in same corner throughout app
3. **Clear Feedback**: Use pulse animation to show active state
4. **Haptic Feedback**: Provide tactile response on tap
5. **Accessibility**: Ensure proper labels for VoiceOver

## Accessibility

Add accessibility support:

```swift
ChatOrb()
    .accessibilityLabel("AI Assistant")
    .accessibilityHint("Double tap to open chat")
    .accessibilityAddTraits(.isButton)
```

## Performance

- **Lightweight**: Uses system materials and native animations
- **GPU Optimized**: Blur and shadow are GPU-accelerated
- **Memory**: Minimal state management (2 @State properties)
- **Battery**: Animations pause when app is backgrounded

## Integration Checklist

- [ ] Add ChatOrb.swift to project
- [ ] Choose position (bottom-right recommended)
- [ ] Add tap handler to show chat interface
- [ ] Test with keyboard appearance
- [ ] Test in light and dark mode
- [ ] Add accessibility labels
- [ ] Test on different screen sizes
- [ ] Verify safe area behavior

## Example: Full Workout Session Integration

```swift
struct WorkoutSessionView: View {
    @State private var showChat = false
    
    var body: some View {
        ZStack {
            // Main workout content
            List {
                ForEach(exercises) { exercise in
                    ExerciseSection(exercise: exercise)
                }
            }
            .listStyle(.insetGrouped)
            
            // Floating chat orb
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    ChatOrb()
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                        .onTapGesture {
                            showChat = true
                        }
                }
            }
        }
        .sheet(isPresented: $showChat) {
            NavigationStack {
                ChatView()
                    .navigationTitle("AI Assistant")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") {
                                showChat = false
                            }
                        }
                    }
            }
        }
    }
}
```

## Future Enhancements

Consider adding:
- Voice input animation (waveform that responds to audio level)
- Notification badge for new messages
- Drag to reposition
- Long press for quick actions
- Color customization based on workout type
- Contextual icon changes (e.g., show timer during rest)

---

**Build Status**: ✅ Compiles and ready to use
**iOS Version**: iOS 18.0+
**Dependencies**: SwiftUI only (no external frameworks)
