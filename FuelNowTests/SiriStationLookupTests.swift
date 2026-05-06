import Foundation
import Testing
@testable import FuelNow

private struct ListEnvelope: Decodable {
    let stations: [Station]
}

private struct FixedLocationResolver: LocationResolving {
    let snapshot: LocationSnapshot
    func resolvedSnapshot() async throws -> LocationSnapshot { snapshot }
}

private actor MockStationFetcher: StationFetching {
    private let result: Result<[Station], Error>

    init(result: Result<[Station], Error>) {
        self.result = result
    }

    func fetchStations(latitude: Double, longitude: Double, radiusKm: Double) async throws -> [Station] {
        try result.get()
    }
}

@Suite("Siri / Station lookup")
enum SiriStationLookupTests {
    @Test static func radiusKmAlwaysReturnsTankerkoenigApiMaximum() throws {
        // TAN-79: Suchradius ist nicht mehr konfigurierbar — `radiusKm` ignoriert UserDefaults
        // und liefert immer das API-Maximum (25 km), unabhängig vom (evtl. aus älteren App-Versionen
        // verbliebenen) gespeicherten Wert.
        let suiteName = "test.intent.radius.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        #expect(StationIntentLookup.radiusKm(defaults: defaults) == AppSettings.SearchRadius.apiMaxKm)

        defaults.set(12, forKey: AppSettings.UserDefaultsKey.searchRadiusKm)
        #expect(
            StationIntentLookup.radiusKm(defaults: defaults) == AppSettings.SearchRadius.apiMaxKm,
            "Migrations-Werte aus alten App-Versionen dürfen den festen 25-km-Radius nicht mehr beeinflussen."
        )
    }

    @Test static func resolvedFuelUsesExplicitOverDefaults() throws {
        let suiteName = "test.intent.fuel.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        defaults.set(FuelType.e10.rawValue, forKey: AppSettings.UserDefaultsKey.preferredFuelType)
        #expect(StationIntentLookup.resolvedFuel(defaults: defaults, explicit: .diesel) == .diesel)
        #expect(StationIntentLookup.resolvedFuel(defaults: defaults, explicit: nil) == .e10)
    }

    @Test static func findNearestReturnsFirstByDistance() async throws {
        let data = try twoStationJSON()
        let stations = try JSONDecoder().decode(ListEnvelope.self, from: data).stations
        let origin = LocationSnapshot(latitude: 52.5, longitude: 13.4, horizontalAccuracy: 10)
        let (defaults, suite) = try isolatedDefaultsPair()
        nonisolated(unsafe) let defaultsForLookup = defaults
        let lookup = StationIntentLookup(
            location: FixedLocationResolver(snapshot: origin),
            fetcher: MockStationFetcher(result: .success(stations)),
            defaults: defaultsForLookup
        )
        let pair = try await lookup.findNearestStation()
        defaults.removePersistentDomain(forName: suite)
        #expect(pair?.station.name == "Near")
    }

    @Test static func findCheapestRespectsFuel() async throws {
        let data = try twoStationJSON()
        let stations = try JSONDecoder().decode(ListEnvelope.self, from: data).stations
        let origin = LocationSnapshot(latitude: 52.5, longitude: 13.4, horizontalAccuracy: 10)
        let (defaults, suite) = try isolatedDefaultsPair()
        defaults.set(FuelType.e10.rawValue, forKey: AppSettings.UserDefaultsKey.preferredFuelType)
        nonisolated(unsafe) let defaultsForLookup = defaults
        let lookup = StationIntentLookup(
            location: FixedLocationResolver(snapshot: origin),
            fetcher: MockStationFetcher(result: .success(stations)),
            defaults: defaultsForLookup
        )
        let diesel = try await lookup.findCheapestStation(explicitFuel: .diesel)
        #expect(diesel?.station.name == "Far")

        let fallbackE10 = try await lookup.findCheapestStation(explicitFuel: nil)
        #expect(fallbackE10?.fuel == .e10)
        #expect(fallbackE10?.station.name == "Near")
        defaults.removePersistentDomain(forName: suite)
    }

    private static func isolatedDefaultsPair() throws -> (UserDefaults, String) {
        let name = "test.intent.lookup.\(UUID().uuidString)"
        return (try #require(UserDefaults(suiteName: name)), name)
    }

    private static func twoStationJSON() throws -> Data {
        let json = """
        {"ok":true,"stations":[
          {"id":"00000000-0000-0000-0000-000000000001","name":"Near","brand":"A","street":"S","place":"P","lat":52.51,"lng":13.4,"dist":0.5,"diesel":1.55,"e5":1.7,"e10":1.45,"isOpen":true,"houseNumber":"1","postCode":10115},
          {"id":"00000000-0000-0000-0000-000000000002","name":"Far","brand":"B","street":"T","place":"Q","lat":52.6,"lng":13.5,"dist":2.0,"diesel":1.40,"e5":1.5,"e10":1.60,"isOpen":true,"houseNumber":"2","postCode":10115}
        ]}
        """
        return try #require(json.data(using: .utf8))
    }
}
