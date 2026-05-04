import Foundation
import Testing
@testable import FuelNow

struct FuelNowDeepLinkTests {
    private let sampleID = UUID(uuidString: "474e5046-deaf-4f9b-9a32-9797b778f047")!

    @Test func rejectsNonFuelNowScheme() {
        let url = URL(string: "https://example.com/station/\(sampleID.uuidString)")!
        #expect(FuelNowDeepLink.parse(url) == nil)
    }

    @Test func parsesMapWithHost() throws {
        let url = try #require(URL(string: "fuelnow://map"))
        #expect(FuelNowDeepLink.parse(url) == .map)
    }

    @Test func parsesMapWithPathOnly() throws {
        let url = try #require(URL(string: "fuelnow:///map"))
        #expect(FuelNowDeepLink.parse(url) == .map)
    }

    @Test func parsesStationWithHost() throws {
        let url = try #require(URL(string: "fuelnow://station/\(sampleID.uuidString)"))
        #expect(FuelNowDeepLink.parse(url) == .station(sampleID))
    }

    @Test func parsesStationWithPathComponents() throws {
        let url = try #require(URL(string: "fuelnow:///station/\(sampleID.uuidString)"))
        #expect(FuelNowDeepLink.parse(url) == .station(sampleID))
    }

    @Test func rejectsMalformedStationUUID() throws {
        let url = try #require(URL(string: "fuelnow://station/not-a-uuid"))
        #expect(FuelNowDeepLink.parse(url) == nil)
    }
}
