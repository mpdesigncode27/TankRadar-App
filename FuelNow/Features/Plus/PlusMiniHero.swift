import StoreKit
import SwiftUI

/// Mini-Hero für FuelNow Plus in den Einstellungen (TAN-78).
///
/// Honest-Conversion-Surface: **kein** „kostenlos testen"-Claim, **kein** Auto-Sheet, kein Nag.
/// Discovery → Decision-Trennung: ein primärer Glas-CTA öffnet das bestehende `PlusUpgradeView`-Sheet (TAN-45).
/// Eine einzelne Glas-Fläche umschließt Inhalt + CTA via `GlassEffectContainer` (kein Glass-on-Glass).
///
/// Loading-Fallback (TAN-90): Wenn nach `loadingTimeout` Sekunden noch kein `product` vorliegt,
/// wechselt der Preis-Block vom `ProgressView` auf einen Fallback-Text — keine endlosen Spinner mehr,
/// wenn StoreKit (z. B. wegen fehlender Sandbox-Apple-ID oder `simctl launch`-Start) leer bleibt.
struct PlusMiniHero: View {
    let product: Product?
    let isLoading: Bool
    let trialOffer: PlusPurchaseController.TrialOfferState?
    let openPlusSheet: () -> Void

    /// Maximalzeit, die ein leerer `ProgressView` aktiv bleiben darf — danach Fallback-Text (TAN-90).
    private static let loadingTimeoutSeconds: UInt64 = 8

    @State private var loadingTimedOut = false

    init(
        product: Product?,
        isLoading: Bool,
        trialOffer: PlusPurchaseController.TrialOfferState? = nil,
        openPlusSheet: @escaping () -> Void
    ) {
        self.product = product
        self.isLoading = isLoading
        self.trialOffer = trialOffer
        self.openPlusSheet = openPlusSheet
    }

    private var trialBadge: String? {
        let audience = PlusPaywallCopy.audience(isSubscriber: false, trialOffer: trialOffer)
        guard let trial = trialOffer else { return nil }
        let duration = PlusPaywallCopy.formattedTrialDuration(offer: trial)
        return PlusPaywallCopy.miniHeroBadge(audience: audience, trialDuration: duration)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: TRSpacing.s) {
            HStack(spacing: TRSpacing.xs) {
                Text("plus.hero.eyebrow")
                    .font(TRTypography.captionSmall())
                    .textCase(.uppercase)
                    .foregroundStyle(TRColors.accentText)
                    .accessibilityAddTraits(.isHeader)
                if let badge = trialBadge {
                    Text(badge)
                        .font(TRTypography.captionSmall())
                        .textCase(.uppercase)
                        .padding(.horizontal, TRSpacing.xs)
                        .padding(.vertical, TRSpacing.xxs)
                        .background(
                            TRColors.accent.opacity(0.15),
                            in: Capsule(style: .continuous)
                        )
                        .overlay(
                            Capsule(style: .continuous)
                                .strokeBorder(TRColors.accent.opacity(0.45), lineWidth: 1)
                        )
                        .foregroundStyle(TRColors.accentText)
                        .accessibilityLabel(badge)
                }
            }

            Text("plus.hero.headline")
                .font(TRTypography.title2())
                .foregroundStyle(TRColors.labelPrimary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: TRSpacing.xs) {
                ForEach(Self.miniBenefits) { benefit in
                    PlusMiniBenefitRow(benefit: benefit)
                }
            }
            .padding(.top, TRSpacing.xxs)

            priceBlock
                .padding(.top, TRSpacing.xs)

            GlassEffectContainer(spacing: TRSpacing.xs) {
                Button(action: openPlusSheet) {
                    Text("settings.plus.miniHero.cta")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.trPrimaryGlass)
                .accessibilityHint(Text("settings.plus.miniHero.cta.a11yHint"))
            }
            .padding(.top, TRSpacing.xs)
        }
        .padding(TRSpacing.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TRColors.backgroundTertiary, in: RoundedRectangle(cornerRadius: TRRadius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: TRRadius.lg, style: .continuous)
                .strokeBorder(TRColors.accent.opacity(0.35), lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private var priceBlock: some View {
        if let product {
            VStack(alignment: .leading, spacing: TRSpacing.xxs) {
                HStack(alignment: .firstTextBaseline, spacing: TRSpacing.xxs) {
                    Text(product.displayPrice)
                        .font(TRTypography.title2())
                        .foregroundStyle(TRColors.labelPrimary)
                        .monospacedDigit()
                    Text("settings.plus.perYear")
                        .font(TRTypography.callout())
                        .foregroundStyle(TRColors.labelSecondary)
                }
                .accessibilityElement(children: .combine)

                if let reframe = Self.priceReframe(for: product) {
                    Text(reframe)
                        .font(TRTypography.caption())
                        .foregroundStyle(TRColors.labelSecondary)
                        .accessibilityHidden(true)
                }
            }
        } else if isLoading, !loadingTimedOut {
            HStack(spacing: TRSpacing.xs) {
                ProgressView()
                Text("settings.plus.priceLoading")
                    .font(TRTypography.callout())
                    .foregroundStyle(TRColors.labelSecondary)
            }
            .task(id: isLoading) {
                guard isLoading else { return }
                try? await Task.sleep(nanoseconds: Self.loadingTimeoutSeconds * 1_000_000_000)
                if !Task.isCancelled, product == nil {
                    loadingTimedOut = true
                }
            }
        } else {
            VStack(alignment: .leading, spacing: TRSpacing.xxs) {
                Text("settings.plus.priceUnavailable")
                    .font(TRTypography.callout())
                    .foregroundStyle(TRColors.labelSecondary)
                Text("settings.plus.priceUnavailable.hint")
                    .font(TRTypography.caption())
                    .foregroundStyle(TRColors.labelTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)
        }
    }

    /// Erzeugt eine kompakte Pro-Monat-Schätzung aus einem Jahresabo-Preis (z. B. „≈ 0,50 € / Monat“).
    /// Liefert `nil`, wenn der Preis nicht extrahiert werden kann oder das Abo nicht jährlich ist.
    static func priceReframe(for product: Product) -> String? {
        guard product.subscription?.subscriptionPeriod.unit == .year else { return nil }
        let yearly = product.price
        guard yearly > 0 else { return nil }
        let monthly = yearly / 12

        let monthlyString = monthly.formatted(product.priceFormatStyle)
        return String(format: String(localized: "settings.plus.priceReframe"), monthlyString)
    }
}

// MARK: - Mini benefits (subset of full Plus benefits)

private extension PlusMiniHero {
    struct MiniBenefit: Identifiable {
        let id: String
        let symbolName: String
        let title: LocalizedStringResource
    }

    static let miniBenefits: [MiniBenefit] = [
        MiniBenefit(id: "carplay", symbolName: "car.fill", title: "plus.benefit.carplay.title"),
        MiniBenefit(id: "future", symbolName: "sparkles", title: "plus.benefit.future.title"),
    ]
}

private struct PlusMiniBenefitRow: View {
    let benefit: PlusMiniHero.MiniBenefit

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: TRSpacing.s) {
            Image(systemName: benefit.symbolName)
                .font(TRTypography.callout())
                .foregroundStyle(TRColors.accentText)
                .frame(width: 20, alignment: .center)
                .accessibilityHidden(true)

            Text(benefit.title)
                .font(TRTypography.callout())
                .foregroundStyle(TRColors.labelPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}
