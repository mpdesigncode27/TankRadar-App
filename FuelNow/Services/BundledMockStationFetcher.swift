import CoreLocation
import Foundation

/// Liefert fest eingebettete Tankstellen aus `mock-stations.json` (App-Bundle), sortiert nach Entfernung zum Suchpunkt.
///
/// Wenn im gewählten Radius keine Station liegt (z. B. Simulator-GPS weit weg von Berlin), werden alle Mock-Einträge geliefert — damit die Karte nicht leer bleibt.
struct BundledMockStationFetcher: StationFetching {
    func fetchStations(latitude: Double, longitude: Double, radiusKm: Double) async throws -> [Station] {
        let all = Self.loadFromBundle()
        let origin = CLLocation(latitude: latitude, longitude: longitude)
        let radiusMeters = max(radiusKm, 1) * 1000

        let sorted = all.sorted {
            Self.distanceMeters(from: origin, station: $0) < Self.distanceMeters(from: origin, station: $1)
        }

        let withinRadius = sorted.filter { Self.distanceMeters(from: origin, station: $0) <= radiusMeters }
        return withinRadius.isEmpty ? sorted : withinRadius
    }

    private static func distanceMeters(from origin: CLLocation, station: Station) -> CLLocationDistance {
        let loc = CLLocation(latitude: station.latitude, longitude: station.longitude)
        return origin.distance(from: loc)
    }

    private static func loadFromBundle() -> [Station] {
        guard let url = Bundle.main.url(forResource: "mock-stations", withExtension: "json") else {
            #if DEBUG
            print("FuelNow: mock-stations.json fehlt im Bundle — keine Mock-Daten.")
            #endif
            return []
        }
        do {
            let data = try Data(contentsOf: url)
            let envelope = try JSONDecoder().decode(MockStationListEnvelope.self, from: data)
            return envelope.stations
        } catch {
            #if DEBUG
            print("FuelNow: Mock-JSON konnte nicht gelesen werden: \(error)")
            #endif
            return []
        }
    }
}

private struct MockStationListEnvelope: Decodable {
    let stations: [Station]
}
