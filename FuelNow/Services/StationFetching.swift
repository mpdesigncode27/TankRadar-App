import Foundation

/// Abstraktion über `TankerkoenigClient`, damit `StationStore` testbar bleibt.
protocol StationFetching: Sendable {
    func fetchStations(latitude: Double, longitude: Double, radiusKm: Double) async throws -> [Station]
}

/// Adapter vom Tankerkönig-Actor auf das Fetch-Protokoll.
struct TankerkoenigStationFetcher: StationFetching {
    let client: TankerkoenigClient

    func fetchStations(latitude: Double, longitude: Double, radiusKm: Double) async throws -> [Station] {
        try await client.fetchStations(latitude: latitude, longitude: longitude, radiusKm: radiusKm)
    }
}
