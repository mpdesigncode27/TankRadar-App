import Foundation
import Testing
@testable import FuelNow

private struct ListEnvelope: Decodable {
    let stations: [Station]
}

private actor MockFetcher: StationFetching {
    private(set) var lastLatitude: Double?
    private(set) var lastLongitude: Double?
    private(set) var lastRadiusKm: Double?
    private var result: Result<[Station], Error>

    init(result: Result<[Station], Error> = .success([])) {
        self.result = result
    }

    func fetchStations(latitude: Double, longitude: Double, radiusKm: Double) async throws -> [Station] {
        lastLatitude = latitude
        lastLongitude = longitude
        lastRadiusKm = radiusKm
        return try result.get()
    }
}

struct QueryServiceTests {
    @Test func sortByDistanceUsesApiDistWhenPresent() throws {
        let stations = try decodeTwoStationFixture().stations
        let sorted = QueryService.sortByDistance(stations: stations, originLatitude: 52.5, originLongitude: 13.4)
        #expect(sorted.map(\.name) == ["Near", "Far"])
    }

    @Test func sortByDistanceFallsBackWhenDistMissing() throws {
        let data = Data(
            """
            {"ok":true,"stations":[
              {"id":"00000000-0000-0000-0000-000000000003","name":"South","brand":"A",
               "street":"S","place":"P","lat":52.49,"lng":13.4,"diesel":1.5,"e5":1.6,
               "e10":1.55,"isOpen":true,"houseNumber":"1","postCode":10115},
              {"id":"00000000-0000-0000-0000-000000000004","name":"North","brand":"B",
               "street":"T","place":"Q","lat":52.53,"lng":13.4,"diesel":1.5,"e5":1.6,
               "e10":1.55,"isOpen":true,"houseNumber":"2","postCode":10115}
            ]}
            """.utf8
        )
        let stations = try JSONDecoder().decode(ListEnvelope.self, from: data).stations
        let sorted = QueryService.sortByDistance(stations: stations, originLatitude: 52.5, originLongitude: 13.4)
        #expect(sorted.first?.name == "South")
        #expect(sorted.last?.name == "North")
    }

    @Test func cheapestPicksLowestPriceForFuel() throws {
        let stations = try decodeTwoStationFixture().stations
        let best = QueryService.cheapest(in: stations, fuel: .diesel, originLatitude: 52.5, originLongitude: 13.4)
        #expect(best?.name == "Far")
        #expect(best?.dieselPrice == 1.4)
    }

    @Test func cheapestTieBreaksByDistance() throws {
        let data = Data(
            """
            {"ok":true,"stations":[
              {"id":"00000000-0000-0000-0000-000000000005","name":"A","brand":"X",
               "street":"S","place":"P","lat":52.51,"lng":13.4,"dist":0.5,"diesel":1.40,
               "e5":1.6,"e10":1.55,"isOpen":true,"houseNumber":"1","postCode":10115},
              {"id":"00000000-0000-0000-0000-000000000006","name":"B","brand":"Y",
               "street":"T","place":"Q","lat":52.6,"lng":13.5,"dist":2.0,"diesel":1.40,
               "e5":1.6,"e10":1.55,"isOpen":true,"houseNumber":"2","postCode":10115}
            ]}
            """.utf8
        )
        let stations = try JSONDecoder().decode(ListEnvelope.self, from: data).stations
        let best = QueryService.cheapest(in: stations, fuel: .diesel, originLatitude: 52.5, originLongitude: 13.4)
        #expect(best?.name == "A")
    }

    @Test func cheapestReturnsNilWhenNoStationOffersFuel() throws {
        let data = Data(
            """
            {"ok":true,"stations":[
              {"id":"00000000-0000-0000-0000-000000000007","name":"OnlyDiesel","brand":"X",
               "street":"S","place":"P","lat":52.51,"lng":13.4,"dist":1,"diesel":1.5,
               "isOpen":true,"houseNumber":"1","postCode":10115}
            ]}
            """.utf8
        )
        let stations = try JSONDecoder().decode(ListEnvelope.self, from: data).stations
        let best = QueryService.cheapest(in: stations, fuel: .e5, originLatitude: 52.5, originLongitude: 13.4)
        #expect(best == nil)
    }

    @Test func fetchStationsSortedByDistanceDelegatesToFetcher() async throws {
        let stations = try decodeTwoStationFixture().stations
        let fetcher = MockFetcher(result: .success(stations))
        let service = QueryService(fetcher: fetcher)
        let out = try await service.fetchStationsSortedByDistance(latitude: 10.5, longitude: 20.25, radiusKm: 12)
        #expect(await fetcher.lastLatitude == 10.5)
        #expect(await fetcher.lastLongitude == 20.25)
        #expect(await fetcher.lastRadiusKm == 12)
        #expect(out.first?.name == "Near")
    }

    @Test func nearestStationReturnsFirstAfterSort() async throws {
        let stations = try decodeTwoStationFixture().stations
        let service = QueryService(fetcher: MockFetcher(result: .success(stations)))
        let nearest = try await service.nearestStation(latitude: 0, longitude: 0, radiusKm: 5)
        #expect(nearest?.name == "Near")
    }

    @Test func cheapestStationUsesFetcherResult() async throws {
        let stations = try decodeTwoStationFixture().stations
        let service = QueryService(fetcher: MockFetcher(result: .success(stations)))
        let cheapest = try await service.cheapestStation(latitude: 0, longitude: 0, radiusKm: 5, fuel: .diesel)
        #expect(cheapest?.name == "Far")
    }

    private func decodeTwoStationFixture() throws -> ListEnvelope {
        let data = Data(
            """
            {"ok":true,"stations":[
              {"id":"00000000-0000-0000-0000-000000000001","name":"Near","brand":"A",
               "street":"S","place":"P","lat":52.51,"lng":13.4,"dist":0.5,"diesel":1.5,
               "e5":1.6,"e10":1.55,"isOpen":true,"houseNumber":"1","postCode":10115},
              {"id":"00000000-0000-0000-0000-000000000002","name":"Far","brand":"B",
               "street":"T","place":"Q","lat":52.6,"lng":13.5,"dist":2.0,"diesel":1.4,
               "e5":1.5,"e10":1.45,"isOpen":true,"houseNumber":"2","postCode":10115}
            ]}
            """.utf8
        )
        return try JSONDecoder().decode(ListEnvelope.self, from: data)
    }
}
