import Foundation
import Observation
import StoreKit

/// Geteilter Zustand für Subscribe-/Restore-Flows von FuelNow Plus.
///
/// Verwendet von `SettingsView` (Plus-Section) und `PlusUpgradeView` (Sheet),
/// damit beide Surfaces dieselbe Pipeline + Fehlerbehandlung benutzen
/// und kein paralleler Logik-Pfad entsteht (TAN-45 Acceptance Criterion
/// „Gleiche Subscription-Pipeline wie Settings").
@Observable @MainActor
final class PlusPurchaseController {
    private(set) var isPurchasing = false
    private(set) var isRestoring = false
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
}
