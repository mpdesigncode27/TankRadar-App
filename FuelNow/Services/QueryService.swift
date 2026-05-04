import CoreLocation
import Foundation

/// Gemeinsame Nearest-/Cheapest-Logik für Karte und App Intents (Tankerkönig-Listen).
///
/// Netzwerkzugriff läuft über ``StationFetching``; Sortierung und Auswahl sind rein lokal und
/// nutzen API-`dist`, falls vorhanden, sonst berechnete Entfernung vom Suchpunkt.
actor QueryService {
    private let fetcher: any StationFetching

    init(fetcher: any StationFetching) {
        self.fetcher = fetcher
    }

    /// Tankstellen im Radius, aufsteigend nach Entfernung zum Suchpunkt.
    func fetchStationsSortedByDistance(latitude: Double, longitude: Double, radiusKm: Double) async throws -> [Station] {
        let raw = try await fetcher.fetchStations(latitude: latitude, longitude: longitude, radiusKm: radiusKm)
        return Self.sortByDistance(stations: raw, originLatitude: latitude, originLongitude: longitude)
    }

    func nearestStation(latitude: Double, longitude: Double, radiusKm: Double) async throws -> Station? {
        let sorted = try await fetchStationsSortedByDistance(latitude: latitude, longitude: longitude, radiusKm: radiusKm)
        return sorted.first
    }

    func cheapestStation(latitude: Double, longitude: Double, radiusKm: Double, fuel: FuelType) async throws -> Station? {
        let raw = try await fetcher.fetchStations(latitude: latitude, longitude: longitude, radiusKm: radiusKm)
        return Self.cheapest(in: raw, fuel: fuel, originLatitude: latitude, originLongitude: longitude)
    }

    /// Entfernung in km vom Suchpunkt zur Tankstelle (`dist` aus `list.php` oder Fallback über Koordinaten).
    nonisolated static func distanceKilometers(fromOriginLatitude originLat: Double, originLng: Double, to station: Station) -> Double {
        if let dist = station.distanceKilometers {
            return dist
        }
        let origin = CLLocation(latitude: originLat, longitude: originLng)
        let target = CLLocation(latitude: station.latitude, longitude: station.longitude)
        return origin.distance(from: target) / 1000
    }

    nonisolated static func sortByDistance(stations: [Station], originLatitude: Double, originLongitude: Double) -> [Station] {
        stations.sorted {
            distanceKilometers(fromOriginLatitude: originLatitude, originLng: originLongitude, to: $0)
                < distanceKilometers(fromOriginLatitude: originLatitude, originLng: originLongitude, to: $1)
        }
    }

    /// Günstigste Tankstelle für die Sorte; bei gleichem Preis gewinnt die geringere Entfernung.
    nonisolated static func cheapest(in stations: [Station], fuel: FuelType, originLatitude: Double, originLongitude: Double) -> Station? {
        let priced: [(station: Station, price: Double)] = stations.compactMap { s in
            guard let p = s.price(for: fuel) else { return nil }
            return (s, p)
        }
        return priced.min { a, b in
            if a.price != b.price { return a.price < b.price }
            let da = distanceKilometers(fromOriginLatitude: originLatitude, originLng: originLongitude, to: a.station)
            let db = distanceKilometers(fromOriginLatitude: originLatitude, originLng: originLongitude, to: b.station)
            return da < db
        }?.station
    }
}
