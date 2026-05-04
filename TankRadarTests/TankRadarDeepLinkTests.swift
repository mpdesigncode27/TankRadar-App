import Foundation
import Testing
@testable import TankRadar

struct TankRadarDeepLinkTests {
    private let sampleID = UUID(uuidString: "474e5046-deaf-4f9b-9a32-9797b778f047")!

    @Test func rejectsNonTankRadarScheme() {
        let url = URL(string: "https://example.com/station/\(sampleID.uuidString)")!
        #expect(TankRadarDeepLink.parse(url) == nil)
    }

    @Test func parsesMapWithHost() throws {
        let url = try #require(URL(string: "tankradar://map"))
        #expect(TankRadarDeepLink.parse(url) == .map)
    }

    @Test func parsesMapWithPathOnly() throws {
        let url = try #require(URL(string: "tankradar:///map"))
        #expect(TankRadarDeepLink.parse(url) == .map)
    }

    @Test func parsesStationWithHost() throws {
        let url = try #require(URL(string: "tankradar://station/\(sampleID.uuidString)"))
        #expect(TankRadarDeepLink.parse(url) == .station(sampleID))
    }

    @Test func parsesStationWithPathComponents() throws {
        let url = try #require(URL(string: "tankradar:///station/\(sampleID.uuidString)"))
        #expect(TankRadarDeepLink.parse(url) == .station(sampleID))
    }

    @Test func rejectsMalformedStationUUID() throws {
        let url = try #require(URL(string: "tankradar://station/not-a-uuid"))
        #expect(TankRadarDeepLink.parse(url) == nil)
    }
}
