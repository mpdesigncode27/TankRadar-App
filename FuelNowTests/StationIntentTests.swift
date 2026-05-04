import AppIntents
import Foundation
import Testing
@testable import FuelNow

private struct StationListEnvelope: Decodable {
    let stations: [Station]
}

private struct MockStationIntentResolver: StationIntentResolving {
    private let byID: [Station.ID: Station]

    init(stations: [Station]) {
        byID = Dictionary(uniqueKeysWithValues: stations.map { ($0.id, $0) })
    }

    func stations(for ids: [Station.ID]) async throws -> [Station] {
        ids.compactMap { byID[$0] }
    }
}

struct StationIntentTests {
    @Test func fuelTypeCoversAllCasesAsAppEnum() {
        #expect(Set(FuelType.allCases) == [.e5, .e10, .diesel])
    }

    @Test func stationEntityPreservesIdentityAndTitle() throws {
        let data = try loadFixture(named: "station-list-sample")
        let station = try #require(try JSONDecoder().decode(StationListEnvelope.self, from: data).stations.first)
        let entity = StationEntity(station: station)
        #expect(entity.id == station.id)
        #expect(entity.title == station.name)
    }

    @Test func stationQueryResolvesViaInjectedResolver() async throws {
        let data = try loadFixture(named: "station-list-sample")
        let station = try #require(try JSONDecoder().decode(StationListEnvelope.self, from: data).stations.first)

        await StationIntentResolution.shared.setResolver(MockStationIntentResolver(stations: [station]))
        let entities = try await StationQuery().entities(for: [station.id])
        await StationIntentResolution.shared.setResolver(EmptyStationIntentResolver())

        #expect(entities.count == 1)
        #expect(entities.first?.id == station.id)
        #expect(entities.first?.title == station.name)
    }

    @Test func stationQueryReturnsEmptyWhenResolverHasNoMatch() async throws {
        let missingID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        await StationIntentResolution.shared.setResolver(EmptyStationIntentResolver())
        let entities = try await StationQuery().entities(for: [missingID])
        #expect(entities.isEmpty)
    }

    private func loadFixture(named name: String) throws -> Data {
        let bundle = Bundle(for: BundleToken.self)
        let url = try #require(bundle.url(forResource: name, withExtension: "json"))
        return try Data(contentsOf: url)
    }
}

private final class BundleToken: NSObject {}
