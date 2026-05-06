/// Zentraler Schalter für Produktfunktionen, die zusätzliche Apple-Freigaben brauchen.
enum FuelNowFeatureFlags {
    /// CarPlay Fueling (`com.apple.developer.carplay-fueling`): erst nach Apple-Approval
    /// Entitlement + Scene in `Info.plist` aktivieren — siehe `docs/CARPLAY.md`.
    ///
    /// Bei `false`: keine CarPlay-Capability im Bundle → Geräte-Archive/TestFlight ohne Fueling-Profil.
    static let isCarPlayCapabilityEnabled = false
}
