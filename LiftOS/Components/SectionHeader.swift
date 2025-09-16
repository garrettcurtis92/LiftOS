import SwiftUI

struct SectionHeader: View {
    let title: String
    let subtitle: String?
    init(_ title: String, subtitle: String? = nil) { self.title = title; self.subtitle = subtitle }
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(TypeScale.title())
            if let subtitle { Text(subtitle).font(TypeScale.subheadline()).foregroundStyle(DS.colors.secondaryLabel) }
        }
        .padding(.horizontal, DS.Space.lg.rawValue)
        .padding(.top, DS.Space.lg.rawValue)
    }
}
