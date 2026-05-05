import Foundation
import StoreKit
import Testing

@testable import FuelNow

/// Reine Copy-/Audience-Logik der FuelNow-Plus-Paywall (TAN-81).
///
/// Tests laufen ohne SKTestSession — die Eingabe ist ein
/// `PlusPurchaseController.TrialOfferState`, der direkt konstruiert wird.
struct PlusPaywallCopyTests {
    private typealias TrialOfferState = PlusPurchaseController.TrialOfferState

    private static func trial(eligible: Bool) -> TrialOfferState {
        TrialOfferState(periodValue: 3, periodUnit: .day, periodCount: 1, isEligible: eligible)
    }

    // MARK: - Audience selection

    @Test func subscriberOverridesEligibilityFlag() {
        #expect(
            PlusPaywallCopy.audience(isSubscriber: true, trialOffer: Self.trial(eligible: true))
                == .activeSubscriber,
            "Aktive Subscriber dürfen keine Trial-Werbung mehr sehen — sonst wäre die Footer-/CTA-Logik widersprüchlich."
        )
    }

    @Test func eligibleTrialBecomesEligibleAudience() {
        #expect(
            PlusPaywallCopy.audience(isSubscriber: false, trialOffer: Self.trial(eligible: true))
                == .eligibleForTrial
        )
    }

    @Test func ineligibleTrialBecomesIneligibleAudience() {
        #expect(
            PlusPaywallCopy.audience(isSubscriber: false, trialOffer: Self.trial(eligible: false))
                == .ineligibleForTrial
        )
    }

    @Test func missingTrialOfferBecomesIneligibleAudience() {
        #expect(
            PlusPaywallCopy.audience(isSubscriber: false, trialOffer: nil) == .ineligibleForTrial
        )
    }

    // MARK: - Period formatting

    @Test func threeDayPeriodFormatsAsLocalizedDays_de() {
        let formatted = PlusPaywallCopy.formattedTrialDuration(
            periodValue: 3,
            periodUnit: .day,
            periodCount: 1,
            locale: Locale(identifier: "de_DE")
        )
        #expect(formatted == "3 Tage")
    }

    @Test func threeDayPeriodFormatsAsLocalizedDays_en() {
        let formatted = PlusPaywallCopy.formattedTrialDuration(
            periodValue: 3,
            periodUnit: .day,
            periodCount: 1,
            locale: Locale(identifier: "en_US")
        )
        #expect(formatted == "3 days")
    }

    @Test func weekPeriodIsConvertedToDays() {
        let formatted = PlusPaywallCopy.formattedTrialDuration(
            periodValue: 1,
            periodUnit: .week,
            periodCount: 1,
            locale: Locale(identifier: "en_US")
        )
        #expect(formatted == "7 days")
    }

    @Test func monthPeriodKeepsMonthUnit() {
        let formatted = PlusPaywallCopy.formattedTrialDuration(
            periodValue: 1,
            periodUnit: .month,
            periodCount: 1,
            locale: Locale(identifier: "en_US")
        )
        #expect(formatted == "1 month")
    }

    @Test func convenienceOverloadMatchesExplicitFields() {
        let offer = TrialOfferState(periodValue: 3, periodUnit: .day, periodCount: 1, isEligible: true)
        let viaOffer = PlusPaywallCopy.formattedTrialDuration(
            offer: offer, locale: Locale(identifier: "en_US"))
        let viaFields = PlusPaywallCopy.formattedTrialDuration(
            periodValue: 3, periodUnit: .day, periodCount: 1, locale: Locale(identifier: "en_US"))
        #expect(viaOffer == viaFields)
    }

    // MARK: - Headline / CTA / badge / footer

    @Test func trialHeadlineIsNilForActiveSubscriber() {
        let headline = PlusPaywallCopy.trialHeadline(
            audience: .activeSubscriber,
            trialDuration: "3 Tage",
            displayPrice: "6,99 €"
        )
        #expect(headline == nil)
    }

    @Test func trialHeadlineIsNilForIneligible() {
        let headline = PlusPaywallCopy.trialHeadline(
            audience: .ineligibleForTrial,
            trialDuration: "3 Tage",
            displayPrice: "6,99 €"
        )
        #expect(headline == nil)
    }

    @Test func trialHeadlineForEligibleContainsDurationAndPrice() throws {
        let headline = PlusPaywallCopy.trialHeadline(
            audience: .eligibleForTrial,
            trialDuration: "3 Tage",
            displayPrice: "6,99 €"
        )
        let unwrapped = try #require(headline)
        #expect(unwrapped.contains("3 Tage"))
        #expect(unwrapped.contains("6,99 €"))
    }

    @Test func ctaLabelEligibleContainsDuration() {
        let label = PlusPaywallCopy.ctaLabel(
            audience: .eligibleForTrial,
            trialDuration: "3 Tage"
        )
        #expect(label.contains("3 Tage"))
    }

    @Test func ctaLabelIneligibleFallsBackToStandardSubscribe() {
        let label = PlusPaywallCopy.ctaLabel(
            audience: .ineligibleForTrial,
            trialDuration: "3 Tage"
        )
        let standard = String(localized: "plus.sheet.subscribe")
        #expect(label == standard)
    }

    @Test func ctaLabelSubscriberShowsActiveStatus() {
        let label = PlusPaywallCopy.ctaLabel(
            audience: .activeSubscriber,
            trialDuration: "3 Tage"
        )
        let active = String(localized: "settings.plus.status.active")
        #expect(label == active)
    }

    @Test func miniHeroBadgeOnlyForEligibleAudience() {
        #expect(
            PlusPaywallCopy.miniHeroBadge(audience: .eligibleForTrial, trialDuration: "3 Tage") != nil
        )
        #expect(
            PlusPaywallCopy.miniHeroBadge(audience: .ineligibleForTrial, trialDuration: "3 Tage") == nil
        )
        #expect(
            PlusPaywallCopy.miniHeroBadge(audience: .activeSubscriber, trialDuration: "3 Tage") == nil
        )
    }

    @Test func footerForEligibleMentionsAutoRenew() {
        let footer = PlusPaywallCopy.footer(audience: .eligibleForTrial, displayPrice: "6,99 €")
        #expect(footer.contains("6,99 €"))
    }

    @Test func footerForIneligibleUsesNonTrialCopy() {
        let footer = PlusPaywallCopy.footer(audience: .ineligibleForTrial, displayPrice: "6,99 €")
        let standard = String(localized: "plus.sheet.footer.cancel")
        #expect(footer == standard)
    }
}
