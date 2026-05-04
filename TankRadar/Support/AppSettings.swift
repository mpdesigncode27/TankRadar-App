import Foundation

/// Gemeinsame `@AppStorage`-Schlüssel und Regeln für Karte + Einstellungen (**TAN-19**).
enum AppSettings {
    enum UserDefaultsKey {
        static let preferredFuelType = "tr.preferredFuelType"
        static let searchRadiusKm = "tr.searchRadiusKm"
        /// Letzter bekannter Standort für App Intents / Siri (`LocationProvider`, ~2 min TTL).
        static let locationCacheLatitude = "tr.locationCache.latitude"
        static let locationCacheLongitude = "tr.locationCache.longitude"
        static let locationCacheHorizontalAccuracy = "tr.locationCache.horizontalAccuracy"
        static let locationCacheRecordedAt = "tr.locationCache.recordedAt"
    }

    enum SearchRadius {
        static let minKm = 1
        static let maxKm = 25
        static let defaultKm = 5

        /// Entspricht dem Setter des Radius-Sliders in `SettingsView`.
        static func clampedKm(sliderValue: Double) -> Int {
            min(maxKm, max(minKm, Int(sliderValue.rounded())))
        }
    }

    enum TankerkoenigAttribution {
        static let infoURL = URL(string: "https://creativecommons.tankerkoenig.de")!
    }
}
