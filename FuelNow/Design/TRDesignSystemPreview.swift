import SwiftUI

/// Design-System-Gallery für Reviews (Linear **TAN-76**).
///
/// Plan-Referenz (Deep Dive): `fuelnow_ios_plan_9b0c0b74.plan.md` — Abschnitt Design System / Preview-Gallery.
///
/// **Reduce Transparency — manuelle Verifikation**
/// - **Canvas:** Preview „Reduce Transparency (simuliert)“ nutzt `simulateReduceTransparency: true`, damit der Banner wie unter aktivem Reduce Transparency sichtbar ist (`\.accessibilityReduceTransparency` ist in SwiftUI nicht setzbar).
/// - **Simulator/Gerät:** *Settings → Accessibility → Display & Text Size → Reduce Transparency* einschalten und die Gallery im Canvas öffnen — Banner erscheint über die echte Environment-Variable.
/// - **Evidence:** Screenshot an Linear **TAN-76** oder im PR anhängen (Simulator + simulierte Preview).
struct TRDesignSystemPreview: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    /// Nur für SwiftUI Previews: Banner anzeigen, wenn die Environment-Variable nicht überschrieben werden kann.
    private let simulateReduceTransparency: Bool

    init(simulateReduceTransparency: Bool = false) {
        self.simulateReduceTransparency = simulateReduceTransparency
    }

    private var showReduceTransparencyAuditBanner: Bool {
        reduceTransparency || simulateReduceTransparency
    }

    private let colorTokenList: [(String, Color)] = [
        ("Accent", TRColors.accent),
        ("AccentMuted", TRColors.accentMuted),
        ("Background", TRColors.background),
        ("BackgroundSecondary", TRColors.backgroundSecondary),
        ("BackgroundTertiary", TRColors.backgroundTertiary),
        ("LabelPrimary", TRColors.labelPrimary),
        ("LabelSecondary", TRColors.labelSecondary),
        ("LabelTertiary", TRColors.labelTertiary),
        ("Separator", TRColors.separator),
        ("Danger", TRColors.danger),
        ("Success", TRColors.success),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: TRSpacing.xl) {
                header
                if showReduceTransparencyAuditBanner {
                    reduceTransparencyBanner
                }
                typographySection
                colorsSection
                spacingSection
                buttonsSection
                cardsSection
                brandSection
            }
            .padding(TRSpacing.m)
        }
        .background(TRColors.background)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: TRSpacing.xs) {
            Text("TR Design System")
                .font(TRTypography.heroTitle())
                .foregroundStyle(TRColors.labelPrimary)
            Text("Typography · Colors · Spacing · Glass")
                .font(TRTypography.subheadline())
                .foregroundStyle(TRColors.labelSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var reduceTransparencyBanner: some View {
        Text("Reduce Transparency aktiv — System reduziert Transparenz; Glas/Material folgt HIG.")
            .font(TRTypography.caption())
            .foregroundStyle(TRColors.labelPrimary)
            .padding(TRSpacing.s)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(TRColors.backgroundTertiary, in: RoundedRectangle(cornerRadius: TRRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: TRRadius.md)
                    .strokeBorder(TRColors.separator, lineWidth: 1)
            )
            .accessibilityIdentifier("trDesignPreview.reduceTransparencyBanner")
    }

    private var typographySection: some View {
        section(title: "Typography") {
            VStack(alignment: .leading, spacing: TRSpacing.s) {
                typoRow("Hero title", TRTypography.heroTitle())
                typoRow("Title", TRTypography.title())
                typoRow("Title 2", TRTypography.title2())
                typoRow("Headline", TRTypography.headline())
                typoRow("Body", TRTypography.body())
                typoRow("Body bold", TRTypography.bodyBold())
                typoRow("Callout", TRTypography.callout())
                typoRow("Subheadline", TRTypography.subheadline())
                typoRow("Caption", TRTypography.caption())
                typoRow("Caption 2", TRTypography.captionSmall())
            }
        }
    }

    private func typoRow(_ label: String, _ font: Font) -> some View {
        VStack(alignment: .leading, spacing: TRSpacing.xxs) {
            Text(label.uppercased())
                .font(TRTypography.captionSmall())
                .foregroundStyle(TRColors.labelTertiary)
            Text("FuelNow · \(label)")
                .font(font)
                .foregroundStyle(TRColors.labelPrimary)
        }
    }

    private var colorsSection: some View {
        section(title: "Colors") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: TRSpacing.m)], spacing: TRSpacing.m) {
                ForEach(colorTokenList, id: \.0) { name, color in
                    colorSwatch(name: name, color: color)
                }
            }
        }
    }

    private func colorSwatch(name: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: TRSpacing.xxs) {
            RoundedRectangle(cornerRadius: TRRadius.sm)
                .fill(color)
                .frame(height: 44)
                .overlay(
                    RoundedRectangle(cornerRadius: TRRadius.sm)
                        .strokeBorder(TRColors.separator.opacity(0.6), lineWidth: 1)
                )
            Text(name)
                .font(TRTypography.caption())
                .foregroundStyle(TRColors.labelSecondary)
        }
    }

    private var spacingSection: some View {
        section(title: "Spacing") {
            HStack(alignment: .bottom, spacing: TRSpacing.xs) {
                spacingChip("xxs", TRSpacing.xxs)
                spacingChip("xs", TRSpacing.xs)
                spacingChip("s", TRSpacing.s)
                spacingChip("m", TRSpacing.m)
                spacingChip("l", TRSpacing.l)
                spacingChip("xl", TRSpacing.xl)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func spacingChip(_ label: String, _ width: CGFloat) -> some View {
        VStack(spacing: TRSpacing.xxs) {
            RoundedRectangle(cornerRadius: TRRadius.sm)
                .fill(TRColors.accent.opacity(0.35))
                .frame(width: max(width, 4), height: 32)
            Text(label)
                .font(TRTypography.captionSmall())
                .foregroundStyle(TRColors.labelTertiary)
        }
    }

    private var buttonsSection: some View {
        section(title: "Buttons") {
            GlassEffectContainer(spacing: TRSpacing.xs) {
                VStack(spacing: TRSpacing.xs) {
                    Button("Primary Glass") {}
                        .buttonStyle(.trPrimaryGlass)
                    Button("Soft Glass") {}
                        .buttonStyle(.trSoft)
                    Button("Outline") {}
                        .buttonStyle(.trOutline)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var cardsSection: some View {
        section(title: "Cards & pills") {
            VStack(alignment: .leading, spacing: TRSpacing.m) {
                Text("Status")
                    .font(TRTypography.caption())
                    .padding(.horizontal, TRSpacing.m)
                    .padding(.vertical, TRSpacing.xs)
                    .trGlassPill(interactive: false)

                VStack(alignment: .leading, spacing: TRSpacing.xs) {
                    Text("Glass-Karte")
                        .font(TRTypography.headline())
                        .foregroundStyle(TRColors.labelPrimary)
                    Text("Modifier `trCardBackground` — gleiche Fläche wie in der App.")
                        .font(TRTypography.callout())
                        .foregroundStyle(TRColors.labelSecondary)
                }
                .padding(TRSpacing.m)
                .frame(maxWidth: .infinity, alignment: .leading)
                .trCardBackground()
            }
        }
    }

    private var brandSection: some View {
        section(title: "Brand") {
            HStack(spacing: TRSpacing.m) {
                Image(.brandGlyph)
                    .resizable()
                    .renderingMode(.template)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 48, height: 48)
                    .foregroundStyle(TRColors.accent)
                Text("BrandGlyph · template · trAccent")
                    .font(TRTypography.callout())
                    .foregroundStyle(TRColors.labelSecondary)
            }
        }
    }

    private func section(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: TRSpacing.m) {
            Text(title.uppercased())
                .font(TRTypography.captionSmall())
                .foregroundStyle(TRColors.labelTertiary)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Previews (Light / Dark / XXL / Reduce Transparency)

#Preview("Gallery — Light") {
    TRDesignSystemPreview()
}

#Preview("Gallery — Dark") {
    TRDesignSystemPreview()
        .preferredColorScheme(.dark)
}

#Preview("Gallery — XXL Type") {
    TRDesignSystemPreview()
        .environment(\.dynamicTypeSize, .accessibility3)
}

#Preview("Gallery — Reduce Transparency (simuliert)") {
    TRDesignSystemPreview(simulateReduceTransparency: true)
}
