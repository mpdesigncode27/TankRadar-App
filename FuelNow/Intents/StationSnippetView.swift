import SwiftUI

/// Kompaktes Siri-/Shortcuts-Snippet mit Design-Tokens (`TRTypography`, `TRSpacing`).
struct StationSnippetView: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: TRSpacing.xs) {
            Text(title)
                .font(TRTypography.headline())
            Text(subtitle)
                .font(TRTypography.subheadline())
                .foregroundStyle(TRColors.labelSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, TRSpacing.xxs)
    }
}

/// Abwärtskompatibler Name aus Phase 6 (TAN-51).
typealias StationIntentSnippetView = StationSnippetView
