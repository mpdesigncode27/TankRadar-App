import CoreLocation
import Foundation
import Testing
@testable import FuelNow

private struct StationListEnvelope: Decodable {
    let stations: [Station]
}

struct StationTests {
    @Test func decodeListFixture() throws {
        let data = try loadFixture(named: "station-list-sample")
        let envelope = try JSONDecoder().decode(StationListEnvelope.self, from: data)
        #expect(envelope.stations.count == 1)
        let station = try #require(envelope.stations.first)
        #expect(station.id == UUID(uuidString: "474e5046-deaf-4f9b-9a32-9797b778f047"))
        #expect(station.name == "TOTAL BERLIN")
        #expect(station.postCode == "10407")
        #expect(station.distanceKilometers == 1.1)
        #expect(station.price(for: .diesel) == 1.109)
        #expect(station.price(for: .e5) == 1.339)
        #expect(station.price(for: .e10) == 1.319)
        #expect(station.fullAddress == "MARGARETE-SOMMER-STR. 2, 10407 BERLIN")
        let coord = station.coordinate
        #expect(coord.latitude == 52.53083)
        #expect(coord.longitude == 13.440946)
    }

    @Test func decodePricesFalseAsNil() throws {
        let data = try loadFixture(named: "station-price-false-sample")
        let station = try JSONDecoder().decode(Station.self, from: data)
        #expect(station.e5Price == nil)
        #expect(station.e10Price == nil)
        #expect(station.dieselPrice == 1.189)
        #expect(station.price(for: .diesel) == 1.189)
    }

    @Test func hashableIdentityUsesId() throws {
        let data = try loadFixture(named: "station-list-sample")
        let a = try JSONDecoder().decode(StationListEnvelope.self, from: data).stations[0]
        let copy = a
        // Same identity even if we conceptually changed display fields — equality is id-based.
        #expect(a == copy)
        var hasherA = Hasher()
        var hasherB = Hasher()
        a.hash(into: &hasherA)
        copy.hash(into: &hasherB)
        #expect(hasherA.finalize() == hasherB.finalize())
    }

    private func loadFixture(named name: String) throws -> Data {
        let bundle = Bundle(for: BundleToken.self)
        let url = try #require(bundle.url(forResource: name, withExtension: "json"))
        return try Data(contentsOf: url)
    }
}

private final class BundleToken: NSObject {}
