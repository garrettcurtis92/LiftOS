import SwiftUI

public extension View {
    @ViewBuilder
    func numericTextTransitionIfAvailable() -> some View {
        if #available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, visionOS 1.0, *) {
            self.contentTransition(.numericText())
        } else {
            self
        }
    }
}
