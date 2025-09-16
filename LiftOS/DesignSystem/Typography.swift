import SwiftUI

enum TypeScale { static func title(_ w: Font.Weight = .bold) -> Font { .title2.weight(w) }; static func headline(_ w: Font.Weight = .semibold) -> Font { .headline.weight(w) }; static func body(_ w: Font.Weight = .regular) -> Font { .body.weight(w) }; static func subheadline(_ w: Font.Weight = .regular) -> Font { .subheadline.weight(w) }; static func footnote(_ w: Font.Weight = .regular) -> Font { .footnote.weight(w) } }
