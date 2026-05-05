import Foundation
import StoreKit

/// Reine Daten-/Stringauswahl für die FuelNow-Plus-Paywall (TAN-81).
///
/// Hält **keinen** Zustand und kennt **kein** SwiftUI — entkoppelt die deterministische
/// Copy-Auswahl von der View, damit Tests ohne `@MainActor`/StoreKit auskommen.
/// Eingaben sind:
///
/// 1. `isSubscriber` aus `EntitlementManager.isPlusSubscriber`
/// 2. optionaler `TrialOfferState` aus `PlusPurchaseController.trialOffer`
/// 3. Produkt-Preis (`Product.displayPrice`) — wird nur in `String(format:)` eingesetzt,
///    damit Apple-konforme Lokalisierung erhalten bleibt.
///
/// Liefert pro UI-Slot (`headline`, `cta`, `miniHeroBadge`, `footer`) die richtige
/// lokalisierte Variante. Nichts wird hartkodiert — die Trial-Dauer kommt immer aus
/// `Product.SubscriptionPeriod` und wird mit `DateComponentsFormatter` gerendert.
enum PlusPaywallCopy {
    /// Drei deterministische Audience-Pfade für die Trial-Copy:
    ///
    /// - `activeSubscriber`: bezahlt bereits Plus → kein Trial-Block, kein Trial-CTA.
    /// - `eligibleForTrial`: kein aktives Abo + Apple bestätigt Erstkäufer → Trial-Block + Trial-CTA.
    /// - `ineligibleForTrial`: kein aktives Abo + Trial bereits eingelöst → Standard-Copy ohne Trial-Claim.
    enum Audience: Equatable, Sendable {
        case activeSubscriber
        case eligibleForTrial
        case ineligibleForTrial
    }

    static func audience(
        isSubscriber: Bool,
        trialOffer: PlusPurchaseController.TrialOfferState?
    ) -> Audience {
        if isSubscriber { return .activeSubscriber }
        if let trial = trialOffer, trial.isEligible { return .eligibleForTrial }
        return .ineligibleForTrial
    }

    /// Lokalisierte Trial-Dauer (z. B. „3 Tage" / „3 days") aus den
    /// app-eigenen Periode-Feldern. Wochen werden in Tage umgerechnet,
    /// weil `DateComponentsFormatter` für `.full` style keine eigene
    /// Wochen-Einheit hat. Monate / Jahre werden in der jeweiligen
    /// Einheit ausgegeben.
    static func formattedTrialDuration(
        periodValue: Int,
        periodUnit: PlusPurchaseController.TrialOfferState.PeriodUnit,
        periodCount: Int = 1,
        locale: Locale = .current
    ) -> String {
        let value = max(1, periodValue * max(1, periodCount))
        var components = DateComponents()
        switch periodUnit {
        case .day:
            components.day = value
        case .week:
            components.day = value * 7
        case .month:
            components.month = value
        case .year:
            components.year = value
        }
        let formatter = DateComponentsFormatter()
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = locale
        formatter.calendar = calendar
        formatter.allowedUnits = [.day, .month, .year]
        formatter.unitsStyle = .full
        return formatter.string(from: components) ?? "\(value)"
    }

    /// Convenience: nimmt direkt einen `TrialOfferState`.
    static func formattedTrialDuration(
        offer: PlusPurchaseController.TrialOfferState,
        locale: Locale = .current
    ) -> String {
        formattedTrialDuration(
            periodValue: offer.periodValue,
            periodUnit: offer.periodUnit,
            periodCount: offer.periodCount,
            locale: locale
        )
    }

    /// Headline-Block für die Paywall direkt unter dem Hero
    /// („3 Tage kostenlos testen, danach 6,99 €/Jahr"). `nil`, wenn keine Trial-Promotion sichtbar sein soll.
    static func trialHeadline(
        audience: Audience,
        trialDuration: String,
        displayPrice: String
    ) -> String? {
        guard audience == .eligibleForTrial else { return nil }
        return String(
            format: String(localized: "plus.trial.headline.eligible"),
            trialDuration,
            displayPrice
        )
    }

    /// Label für den primären Subscribe-Button.
    static func ctaLabel(audience: Audience, trialDuration: String) -> String {
        switch audience {
        case .activeSubscriber:
            return String(localized: "settings.plus.status.active")
        case .eligibleForTrial:
            return String(
                format: String(localized: "plus.trial.cta.eligible"),
                trialDuration
            )
        case .ineligibleForTrial:
            return String(localized: "plus.sheet.subscribe")
        }
    }

    /// Kleines Badge im Settings-Mini-Hero („3 Tage kostenlos"). `nil`, wenn Trial nicht beworben werden soll.
    static func miniHeroBadge(audience: Audience, trialDuration: String) -> String? {
        guard audience == .eligibleForTrial else { return nil }
        return String(
            format: String(localized: "plus.trial.miniHero.badge"),
            trialDuration
        )
    }

    /// Footer-Hinweis am Ende der Paywall — ehrliche Renewal-Erklärung.
    static func footer(
        audience: Audience,
        displayPrice: String
    ) -> String {
        switch audience {
        case .activeSubscriber, .eligibleForTrial:
            return String(
                format: String(localized: "plus.sheet.footer.cancel.trial"),
                displayPrice
            )
        case .ineligibleForTrial:
            return String(localized: "plus.sheet.footer.cancel")
        }
    }
}
