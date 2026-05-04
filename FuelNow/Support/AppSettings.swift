import Foundation

/// Gemeinsame `@AppStorage`-Schlüssel und Regeln für Karte + Einstellungen (**TAN-19**).
enum AppSettings {
    enum UserDefaultsKey {
        static let preferredFuelType = "tr.preferredFuelType"
        static let searchRadiusKm = "tr.searchRadiusKm"
        /// Hell / Dunkel / System (`AppearancePreference.rawValue`).
        static let appearancePreference = "tr.appearancePreference"
        /// Letzter bekannter Standort für App Intents / Siri (`LocationProvider`, ~2 min TTL).
        static let locationCacheLatitude = "tr.locationCache.latitude"
        static let locationCacheLongitude = "tr.locationCache.longitude"
        static let locationCacheHorizontalAccuracy = "tr.locationCache.horizontalAccuracy"
        static let locationCacheRecordedAt = "tr.locationCache.recordedAt"
        /// Kurzbefehle / Custom-URL: Tankstelle auf der Karte fokussieren (`MapDeepLinkStore`).
        static let pendingMapStationFocusID = "tr.pendingMapStationFocusID"
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

    /// Gespeicherte UI-Erscheinung; `system` folgt iOS Hell/Dunkel.
    enum AppearancePreference: String, CaseIterable, Identifiable {
        case system
        case light
        case dark

        var id: String { rawValue }

        static func resolved(storedRaw: String) -> AppearancePreference {
            Self(rawValue: storedRaw) ?? .system
        }
    }
}
