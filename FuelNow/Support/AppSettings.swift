import Foundation

/// Gemeinsame `@AppStorage`-Schlüssel und Regeln für Karte + Einstellungen (**TAN-19**).
enum AppSettings {
    enum UserDefaultsKey {
        static let preferredFuelType = "tr.preferredFuelType"
        /// Veraltet seit TAN-79: Suchradius wurde aus den Settings entfernt und ist
        /// fest auf das Tankerkönig-API-Maximum (25 km) gesetzt. Der Key bleibt definiert,
        /// damit alte Werte in `UserDefaults` nicht aktiv aufgeräumt werden müssen — die
        /// App liest ihn nicht mehr.
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

    /// Suchradius für Tankerkönig-`list.php` (TAN-79).
    ///
    /// Seit TAN-79 ist der Suchradius aus den User-Settings entfernt und fest auf das
    /// **API-Maximum von 25 km** gesetzt. Tankerkönig erlaubt im freien Tier
    /// (`creativecommons.tankerkoenig.de`) keinen größeren Radius und untersagt das
    /// Bulk-Mirroring; „alle Tankstellen anzeigen" bedeutet daher konsequent
    /// „alle im 25-km-Umkreis um den Standort".
    enum SearchRadius {
        /// Tankerkönig-API-Maximum für `rad` in `list.php`.
        static let apiMaxKm: Double = 25
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
