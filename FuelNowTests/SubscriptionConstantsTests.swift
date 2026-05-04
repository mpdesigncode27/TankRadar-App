import Foundation
import Testing

@testable import FuelNow

struct SubscriptionConstantsTests {
    @Test func plusYearlyProductIDMatchesBundleConvention() {
        #expect(SubscriptionConstants.plusYearlyProductID == "com.vibecoding.FuelNow.subscription.year")
        #expect(SubscriptionConstants.productIDs == [SubscriptionConstants.plusYearlyProductID])
    }
}
