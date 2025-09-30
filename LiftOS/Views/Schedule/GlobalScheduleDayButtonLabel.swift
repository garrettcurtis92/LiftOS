import SwiftUI

struct DayButtonLabel: View {
    let label: String
    let isSelected: Bool
    let fill: Color
    let stroke: Color
    let foreground: Color
    let selectionNS: Namespace.ID

    var body: some View {
        Text(label)
            .font(TypeScale.subheadline(.semibold))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(
                ZStack {
                    Capsule(style: .continuous)
                        .fill(fill)
                    if isSelected {
                        Capsule(style: .continuous)
                            .fill(.thinMaterial)
                            .matchedGeometryEffect(id: "day-highlight", in: selectionNS)
                    }
                }
            )
            .overlay(
                Capsule(style: .continuous)
                    .strokeBorder(stroke, lineWidth: 1)
            )
            .foregroundStyle(foreground)
    }
}
