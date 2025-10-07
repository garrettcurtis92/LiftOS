import SwiftUI
import UIKit
import Combine

@MainActor
final class ChatController: ObservableObject {
    enum Mode: Equatable { case hidden, orb, docked, expanded }

    static let shared = ChatController()

    // Presentation
    @Published var mode: Mode = .orb
    @Published var hasUnread: Bool = false

    // Input state shared by dock & expanded
    @Published var draft: String = ""
    @Published var isThinking: Bool = false

    // Config
    var isTrainOnly: Bool = false     // you can toggle per tab
    var isPerTab: Bool = false        // or global

    // Haptics
    func tapHaptic() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    func successHaptic() { UINotificationFeedbackGenerator().notificationOccurred(.success) }

    // Transitions
    func presentDock() { mode = .docked; tapHaptic() }
    func presentExpanded() { mode = .expanded; tapHaptic() }
    func presentOrb() { mode = .orb }
    func hide() { mode = .hidden }
}
