import StoreKit
import Testing

@testable import FuelNow

/// Deterministische Checks für den geteilten Purchase-/Restore-State.
/// StoreKit-Session-Tests gehören in TAN-62.
@MainActor
struct PlusPurchaseControllerTests {
    @Test func initialStateIsIdle() {
        let controller = PlusPurchaseController()
        #expect(controller.isPurchasing == false)
        #expect(controller.isRestoring == false)
        #expect(controller.isBusy == false)
        #expect(controller.alertMessage == nil)
        #expect(controller.trialOffer == nil)
    }

    @Test func alertMessageIsMutable() {
        let controller = PlusPurchaseController()
        controller.alertMessage = "Test"
        #expect(controller.alertMessage == "Test")
        controller.alertMessage = nil
        #expect(controller.alertMessage == nil)
    }

    /// Stellt sicher, dass die UI direkt einen `TrialOfferState` annehmen kann
    /// und damit Audience-Auswahl + Formatierung deterministisch testbar bleiben.
    @Test func trialOfferStatePropagatesAllFields() {
        let state = PlusPurchaseController.TrialOfferState(
            periodValue: 3,
            periodUnit: .day,
            periodCount: 1,
            isEligible: true
        )
        #expect(state.periodValue == 3)
        #expect(state.periodUnit == .day)
        #expect(state.periodCount == 1)
        #expect(state.isEligible == true)
    }

    /// Eligibility-Branching: derselbe `Product` darf zu unterschiedlicher Copy führen,
    /// je nachdem ob der Apple-Kunde noch Anspruch auf den Free-Trial hat.
    @Test func eligibleVsIneligibleProducesDistinctTrialState() {
        let eligible = PlusPurchaseController.TrialOfferState(
            periodValue: 3,
            periodUnit: .day,
            periodCount: 1,
            isEligible: true
        )
        let ineligible = PlusPurchaseController.TrialOfferState(
            periodValue: 3,
            periodUnit: .day,
            periodCount: 1,
            isEligible: false
        )
        #expect(eligible != ineligible)
        #expect(
            PlusPaywallCopy.audience(isSubscriber: false, trialOffer: eligible) == .eligibleForTrial
        )
        #expect(
            PlusPaywallCopy.audience(isSubscriber: false, trialOffer: ineligible) == .ineligibleForTrial
        )
    }

    /// `PeriodUnit.init(_:)` muss alle bekannten StoreKit-Einheiten 1:1 abbilden.
    @Test func periodUnitMapsAllStoreKitUnits() {
        #expect(PlusPurchaseController.TrialOfferState.PeriodUnit(.day) == .day)
        #expect(PlusPurchaseController.TrialOfferState.PeriodUnit(.week) == .week)
        #expect(PlusPurchaseController.TrialOfferState.PeriodUnit(.month) == .month)
        #expect(PlusPurchaseController.TrialOfferState.PeriodUnit(.year) == .year)
    }
}
