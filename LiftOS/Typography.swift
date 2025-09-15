//
//  Typography.swift
//  LiftOS
//
//  Created by Garrett Curtis on 9/13/25.
//
import SwiftUI

enum TypeScale {
    static func title(_ weight: Font.Weight = .bold) -> Font { .title2.weight(weight) }
    static func headline(_ weight: Font.Weight = .semibold) -> Font { .headline.weight(weight) }
    static func body(_ weight: Font.Weight = .regular) -> Font { .body.weight(weight) }
    static func subheadline(_ weight: Font.Weight = .regular) -> Font { .subheadline.weight(weight) }
    static func footnote(_ weight: Font.Weight = .regular) -> Font { .footnote.weight(weight) }
}
