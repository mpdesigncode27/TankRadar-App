import Foundation

/// Liefert dem CarPlay-Scene-Delegate (TAN-56) die Plus-Wahrheit, ohne ihn an den
/// konkreten `EntitlementManager` zu binden.
///
/// Der Default-Provider ist eine **eigene** `EntitlementManager`-Instanz pro
/// CarPlay-Scene; `Transaction.currentEntitlements` ist app-weit dieselbe Wahrheit
/// (StoreKit hält die Quelle), sodass App-Scene und CarPlay-Scene konsistent
/// bleiben. Tests injizieren via `FuelNowCarPlaySceneDelegate.entitlementProviderFactory`
/// einen Stub und sparen sich StoreKit komplett.
@MainActor
protocol CarPlayEntitlementProviding: AnyObject {
    /// Spiegelt den aktuellen Plus-Status. Muss `@Observable`-Beobachtung erlauben,
    /// damit der Scene-Delegate auf einen Flip reagieren kann.
    var isCarPlayUnlocked: Bool { get }

    /// Wird genau einmal pro Scene-Connect aufgerufen, bevor der erste Template-
    /// Render passiert. Default-Implementierung: lädt Produkte + refresht
    /// Entitlements + abonniert `Transaction.updates` (siehe `EntitlementManager`).
    func start() async
}

extension EntitlementManager: CarPlayEntitlementProviding {}
