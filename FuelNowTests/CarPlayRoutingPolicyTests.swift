import Testing
@testable import FuelNow

/// Unit-Tests für die reine CarPlay-Routing-Entscheidung (TAN-56). Bewusst frei
/// von `CarPlay`/`UIKit` — der Scene-Delegate selbst lebt erst im CarPlay-
/// Simulator (TAN-59 / Sandbox-QA).
struct CarPlayRoutingPolicyTests {
    @Test("Plus aktiv → POI-Pfad (.plus)")
    func unlockedRoutesToPlus() {
        #expect(CarPlayRoutingPolicy.route(forCarPlayUnlocked: true) == .plus)
    }

    @Test("Kein Plus → ehrlicher Limited-Pfad (.limited)")
    func lockedRoutesToLimited() {
        #expect(CarPlayRoutingPolicy.route(forCarPlayUnlocked: false) == .limited)
    }

    @Test("Routing ist deterministisch & idempotent (kein Hidden State)")
    func routingIsPureFunction() {
        #expect(
            CarPlayRoutingPolicy.route(forCarPlayUnlocked: true)
                == CarPlayRoutingPolicy.route(forCarPlayUnlocked: true)
        )
        #expect(
            CarPlayRoutingPolicy.route(forCarPlayUnlocked: false)
                == CarPlayRoutingPolicy.route(forCarPlayUnlocked: false)
        )
        #expect(
            CarPlayRoutingPolicy.route(forCarPlayUnlocked: true)
                != CarPlayRoutingPolicy.route(forCarPlayUnlocked: false)
        )
    }
}
