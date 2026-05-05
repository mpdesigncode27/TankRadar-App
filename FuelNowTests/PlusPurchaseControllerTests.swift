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
    }

    @Test func alertMessageIsMutable() {
        let controller = PlusPurchaseController()
        controller.alertMessage = "Test"
        #expect(controller.alertMessage == "Test")
        controller.alertMessage = nil
        #expect(controller.alertMessage == nil)
    }
}
