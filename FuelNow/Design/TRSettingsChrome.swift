import SwiftUI

// MARK: - Section chrome (Preferences-style layout)

/// Kleine, auszeichnende Sektionsüberschrift oberhalb von Glas-Karten (oberer Referenz-Screen).
struct TRSettingsSectionHeader: View {
    private let title: LocalizedStringResource
    private let accent: Bool

    init(_ title: LocalizedStringResource, accent: Bool = false) {
        self.title = title
        self.accent = accent
    }

    var body: some View {
        Text(title)
            .font(TRTypography.captionSmall())
            .fontWeight(.semibold)
            .tracking(1.1)
            .foregroundStyle(accent ? TRColors.accentText : TRColors.labelSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }
}

/// Eine zusammenhängende Glas-Karte mit mehreren Zeilen (z. B. Schalter- oder Steuerungsgruppe).
struct TRGroupedGlassCard<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(TRSpacing.m)
            .trCardBackground()
    }
}
