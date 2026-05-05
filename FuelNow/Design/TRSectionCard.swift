import SwiftUI

/// TR-Liquid-Glass-Section wie auf dem Tankstellen-Detail — für Settings und andere Feature-Screens.
struct TRSectionCard<Content: View>: View {
    let title: String
    var accentTitle: Bool = false
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: TRSpacing.xs) {
            Text(title)
                .font(TRTypography.caption())
                .foregroundStyle(accentTitle ? TRColors.accentText : TRColors.labelSecondary)
                .accessibilityAddTraits(.isHeader)
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(TRSpacing.m)
        .trCardBackground()
    }
}
