import Testing
@testable import FuelNow

/// Deterministic checks only — StoreKit session tests belong in TAN-62.
@MainActor
struct EntitlementManagerTests {
    @Test func initialSubscriptionGateIsClosed() {
        let manager = EntitlementManager()
        #expect(manager.isPlusSubscriber == false)
        #expect(manager.isCarPlayUnlocked == false)
        #expect(manager.products.isEmpty)
    }
}
