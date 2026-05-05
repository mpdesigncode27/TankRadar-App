import Foundation

/// Abstraktion für Tests; Produktion: ``LocationProvider``.
protocol LocationResolving: Sendable {
    func resolvedSnapshot() async throws -> LocationSnapshot
}

extension LocationProvider: LocationResolving {}

/// Orchestriert Standort (Cache + One-Shot) und Tankerkönig-Abfragen für Siri/Shortcuts.
actor StationIntentLookup {
    static let shared = StationIntentLookup()

    private let location: any LocationResolving
    private let query: QueryService
    /// `UserDefaults` ist laut Apple threadsicher; wir lesen nur Primitive für Radius/Spritart.
    nonisolated(unsafe) private let defaults: UserDefaults

    init(
        location: any LocationResolving = LocationProvider(),
        fetcher: any StationFetching = TankerkoenigStationFetcher(client: TankerkoenigClient()),
        defaults: UserDefaults = .standard
    ) {
        self.location = location
        self.query = QueryService(fetcher: fetcher)
        self.defaults = defaults
    }

    /// Liefert den zuletzt verwendeten Standort-Snapshot mit, damit Snippets Entfernung ohne zweiten GPS-Zyklus formatieren können.
    func findNearestStation() async throws -> (station: Station, origin: LocationSnapshot)? {
        let snap = try await location.resolvedSnapshot()
        let radius = Self.radiusKm(defaults: defaults)
        guard let station = try await query.nearestStation(
            latitude: snap.latitude,
            longitude: snap.longitude,
            radiusKm: radius
        ) else {
            return nil
        }
        return (station, snap)
    }

    /// `explicitFuel == nil` → bevorzugte Sorte aus `UserDefaults` (`AppSettings.UserDefaultsKey.preferredFuelType`).
    func findCheapestStation(explicitFuel: FuelType?) async throws -> (station: Station, fuel: FuelType, origin: LocationSnapshot)? {
        let snap = try await location.resolvedSnapshot()
        let radius = Self.radiusKm(defaults: defaults)
        let fuel = Self.resolvedFuel(defaults: defaults, explicit: explicitFuel)
        guard let station = try await query.cheapestStation(
            latitude: snap.latitude,
            longitude: snap.longitude,
            radiusKm: radius,
            fuel: fuel
        ) else {
            return nil
        }
        return (station, fuel, snap)
    }

    /// TAN-79: Suchradius ist nicht mehr konfigurierbar. Liefert immer das Tankerkönig-API-Maximum.
    /// Der `defaults`-Parameter bleibt aus Quell-/Test-Stabilität erhalten, wird aber bewusst ignoriert.
    nonisolated static func radiusKm(defaults _: UserDefaults) -> Double {
        AppSettings.SearchRadius.apiMaxKm
    }

    nonisolated static func resolvedFuel(defaults: UserDefaults, explicit: FuelType?) -> FuelType {
        if let explicit { return explicit }
        let raw = defaults.string(forKey: AppSettings.UserDefaultsKey.preferredFuelType) ?? FuelType.e10.rawValue
        return FuelType(rawValue: raw) ?? .e10
    }
}
