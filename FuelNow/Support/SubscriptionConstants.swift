import Foundation

/// Produkt-IDs für FuelNow Plus — müssen mit App Store Connect (Linear TAN-42) und `FuelNowPlus.storekit` übereinstimmen.
enum SubscriptionConstants {
    /// Jahresabo (EUR-Basispreis kommt aus StoreKit / ASC, nicht hardcodieren für UI).
    static let plusYearlyProductID = "com.vibecoding.fuelnow.subscription.year"

    static let productIDs: [String] = [plusYearlyProductID]
}
