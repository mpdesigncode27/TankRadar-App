import Foundation
import Observation
import StoreKit

/// Geteilter Zustand für Subscribe-/Restore-Flows von FuelNow Plus.
///
/// Verwendet von `SettingsView` (Plus-Section) und `PlusUpgradeView` (Sheet),
/// damit beide Surfaces dieselbe Pipeline + Fehlerbehandlung benutzen
/// und kein paralleler Logik-Pfad entsteht (TAN-45 Acceptance Criterion
/// „Gleiche Subscription-Pipeline wie Settings").
///
/// Hält außerdem den **Free-Trial-Eligibility**-State (TAN-81) als
/// `@MainActor`-Snapshot — UI liest direkt `trialOffer`, kein
/// erneutes Polling pro View-Render.
@Observable @MainActor
final class PlusPurchaseController {
    private(set) var isPurchasing = false
    private(set) var isRestoring = false

    /// `nil`, solange das Produkt noch nicht geprüft wurde oder kein
    /// `introductoryOffer` mit `paymentMode == .freeTrial` hinterlegt ist.
    /// Andernfalls Periode + Eligibility-Flag des aktuellen Apple-Kunden.
    private(set) var trialOffer: TrialOfferState?

    #if DEBUG
    /// DEBUG-only Stand-In für `Product.displayPrice`, falls die Paywall
    /// in einem Simulator ohne geladenen StoreKit-Configuration-File
    /// (z. B. via `xcrun simctl launch` für Linear-Evidence-Screenshots)
    /// gerendert wird. Wird ausschließlich vom Mock-Launch-Arg gesetzt.
    private(set) var debugMockDisplayPrice: String?
    #endif

    var alertMessage: String?

    var isBusy: Bool { isPurchasing || isRestoring }

    init() {}

    /// Kauft das übergebene Produkt über den `EntitlementManager`. UI-Cancellations
    /// werden still verworfen; Pending- und unbekannte Ergebnisse landen im
    /// `alertMessage`-Slot zur Anzeige durch die jeweilige View.
    func subscribe(to product: Product, via entitlementManager: EntitlementManager) async {
        guard !isBusy else { return }
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            try await entitlementManager.purchase(product)
        } catch EntitlementManagerError.userCancelled {
            return
        } catch EntitlementManagerError.pending {
            alertMessage = String(localized: "settings.plus.error.pending")
        } catch EntitlementManagerError.unknownPurchaseResult {
            alertMessage = String(localized: "settings.plus.error.generic")
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    func restore(via entitlementManager: EntitlementManager) async {
        guard !isBusy else { return }
        isRestoring = true
        defer { isRestoring = false }
        do {
            try await entitlementManager.restorePurchases()
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    /// Aktualisiert den `trialOffer`-Snapshot für das übergebene Produkt.
    ///
    /// Liest die Periode aus `Product.SubscriptionInfo.introductoryOffer`
    /// und die Apple-Kunden-Eligibility asynchron über
    /// `Product.SubscriptionInfo.isEligibleForIntroOffer`. Setzt `nil`,
    /// wenn das Produkt keinen Free-Trial bietet (z. B. Promotional Offer
    /// oder kein Intro Offer aktiv).
    func refreshTrialOffer(for product: Product) async {
        #if DEBUG
        if applyDebugMockIfRequested() { return }
        #endif

        guard let subscription = product.subscription,
              let intro = subscription.introductoryOffer,
              intro.paymentMode == .freeTrial
        else {
            trialOffer = nil
            return
        }

        let eligible = await subscription.isEligibleForIntroOffer
        let unit = TrialOfferState.PeriodUnit(intro.period.unit)
        trialOffer = TrialOfferState(
            periodValue: intro.period.value,
            periodUnit: unit,
            periodCount: intro.periodCount,
            isEligible: eligible
        )
    }

    #if DEBUG
    /// Lokales DEBUG-Hilfsmittel: Wenn das Launch-Arg
    /// `--mock-trial-offer-eligible` gesetzt ist, injiziert ein
    /// 3-Tage-Eligible-Trial-Snapshot ohne echte StoreKit-Anfrage. Wird
    /// ausschließlich für Linear-Evidence-Screenshots im Simulator
    /// genutzt — `xcrun simctl launch` respektiert die
    /// Scheme-`.storekit`-Konfiguration nicht und kann deshalb keine
    /// echten Produkte laden.
    @discardableResult
    func applyDebugMockIfRequested() -> Bool {
        let arguments = ProcessInfo.processInfo.arguments
        guard arguments.contains("--mock-trial-offer-eligible") else { return false }
        trialOffer = TrialOfferState(
            periodValue: 3,
            periodUnit: .day,
            periodCount: 1,
            isEligible: true
        )
        debugMockDisplayPrice = "5,99 €"
        return true
    }
    #endif

    /// Ergebnis-Snapshot der Free-Trial-Eligibility-Prüfung.
    ///
    /// Hält die Periode bewusst als App-eigene Werte (kein
    /// `Product.SubscriptionPeriod`), damit Tests ohne `SKTestSession`
    /// deterministisch konstruieren können — Apples Initializer ist
    /// `internal`.
    ///
    /// - `periodValue` × `periodUnit`: Trial-Dauer pro Wiederholung.
    /// - `periodCount`: Anzahl der Wiederholungen (für Free-Trials i. d. R. `1`).
    /// - `isEligible`: nur `true`, wenn der Apple-Kunde noch keinen Trial in
    ///   dieser Subscription-Group eingelöst hat (Apple-seitige Regel).
    struct TrialOfferState: Equatable, Sendable {
        var periodValue: Int
        var periodUnit: PeriodUnit
        var periodCount: Int
        var isEligible: Bool

        enum PeriodUnit: String, Equatable, Sendable {
            case day, week, month, year

            init(_ unit: Product.SubscriptionPeriod.Unit) {
                switch unit {
                case .day: self = .day
                case .week: self = .week
                case .month: self = .month
                case .year: self = .year
                @unknown default: self = .day
                }
            }
        }
    }
}
