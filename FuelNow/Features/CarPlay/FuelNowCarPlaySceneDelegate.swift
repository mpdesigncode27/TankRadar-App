#if canImport(CarPlay)
import CarPlay
import Foundation
import Observation
import UIKit

/// CarPlay-Scene-Delegate für FuelNow (TAN-56) — die einzige Klasse, die mit
/// `CPInterfaceController` redet.
///
/// Wird vom System via `Info.plist`-Eintrag (`UISceneDelegateClassName =
/// $(PRODUCT_MODULE_NAME).FuelNowCarPlaySceneDelegate`) instanziiert, sobald das
/// iPhone an ein CarPlay-fähiges Headunit verbindet. Die Klasse erfüllt die DoD
/// von TAN-56:
///
/// * **Plus-Gating zuerst:** Vor dem ersten `setRootTemplate` wird
///   `CarPlayEntitlementProviding.isCarPlayUnlocked` gelesen — keine Pseudo-POIs
///   ohne aktives Plus.
/// * **Single Source of Truth:** Default-Provider ist `EntitlementManager`, der
///   `Transaction.currentEntitlements` beobachtet — gleiche Wahrheit wie die
///   iPhone-App, weil StoreKit prozessweit konsistent ist.
/// * **Flip-Reaktion:** `withObservationTracking` re-armt sich nach jedem Change,
///   sodass `setRootTemplate` beim Plus-Wechsel während laufender Session neu
///   gesetzt wird (Foundation für TAN-58 / Aboablauf-Edgecases).
/// * **Stub-Templates:** `CPListTemplate` (Plus) und `CPInformationTemplate`
///   (Limited) — produktive Inhalte folgen in TAN-55 / TAN-57.
///
/// Tests injizieren `entitlementProviderFactory`, sodass die Routing-Pipeline
/// ohne StoreKit verifiziert werden kann; reine Routing-Logik liegt in
/// `CarPlayRoutingPolicy`.
final class FuelNowCarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    /// Test-Hook — Default ist eine eigene `EntitlementManager`-Instanz pro Scene.
    /// `EntitlementManager` selbst ist `@MainActor`, deswegen muss die Factory
    /// auch `@MainActor` sein.
    static var entitlementProviderFactory: @MainActor () -> any CarPlayEntitlementProviding = {
        EntitlementManager()
    }

    private var interfaceController: CPInterfaceController?
    private var entitlementProvider: (any CarPlayEntitlementProviding)?
    private var lastRoute: CarPlayRoute?
    private var didStartObserving = false

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        self.interfaceController = interfaceController
        let provider = Self.entitlementProviderFactory()
        entitlementProvider = provider
        Task { @MainActor in
            await provider.start()
            applyCurrentRoute(animated: false)
            armEntitlementObservation()
        }
    }

    // MARK: - Observation

    /// Standard-`Observation`-Pattern: nach jedem Change `withObservationTracking`
    /// neu installieren. So bekommen wir kontinuierliche Updates ohne
    /// `Combine`/`@Published`.
    @MainActor
    private func armEntitlementObservation() {
        didStartObserving = true
        guard let provider = entitlementProvider else { return }
        withObservationTracking {
            _ = provider.isCarPlayUnlocked
        } onChange: { [weak self] in
            // `onChange` wird vom Observation-Framework off-main aufgerufen — wir
            // hoppen sofort auf den Main-Actor, lesen den neuen Wert und re-armen.
            Task { @MainActor [weak self] in
                guard let self, self.didStartObserving else { return }
                self.applyCurrentRoute(animated: true)
                self.armEntitlementObservation()
            }
        }
    }

    // MARK: - Routing

    @MainActor
    private func applyCurrentRoute(animated: Bool) {
        guard let interfaceController else { return }
        let unlocked = entitlementProvider?.isCarPlayUnlocked ?? false
        let route = CarPlayRoutingPolicy.route(forCarPlayUnlocked: unlocked)
        guard route != lastRoute else { return }
        lastRoute = route
        interfaceController.setRootTemplate(makeTemplate(for: route), animated: animated, completion: nil)
    }

    @MainActor
    private func makeTemplate(for route: CarPlayRoute) -> CPTemplate {
        switch route {
        case .plus:
            // Stub bis TAN-55: leerer `CPListTemplate` als ehrlicher Platzhalter.
            // TAN-55 ersetzt das durch `CPPointOfInterestTemplate` + StationStore-Adapter.
            CPListTemplate(
                title: String(localized: "carplay.plus.placeholder.title"),
                sections: []
            )
        case .limited:
            // Stub bis TAN-57: bereits ehrliches `CPInformationTemplate` mit
            // lokalisierbaren Stub-Strings (`carplay.locked.*`). TAN-57 verfeinert
            // das Copy + ergänzt ggf. weitere Items / Layouts.
            CPInformationTemplate(
                title: String(localized: "carplay.locked.title"),
                layout: .leading,
                items: [
                    CPInformationItem(
                        title: String(localized: "carplay.locked.body"),
                        detail: nil
                    ),
                ],
                actions: []
            )
        }
    }
}

// `didDisconnect` muss in einer Extension stehen, sonst diagnostiziert der
// Compiler fälschlich „nearly matches optional requirement
// `templateApplicationScene(_:didSelect:)`" — Apples offizielle Empfehlung.
extension FuelNowCarPlaySceneDelegate {
    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnect interfaceController: CPInterfaceController
    ) {
        self.interfaceController = nil
        entitlementProvider = nil
        lastRoute = nil
        didStartObserving = false
    }
}
#endif
