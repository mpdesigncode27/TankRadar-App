import CoreLocation
import MapKit
import Testing
@testable import FuelNow

private struct StationListEnvelope: Decodable {
    let stations: [Station]
}

struct StationMapClusteringTests {
    /// Vier Stationen im ~30–40-m-Raster — bei großem Kartenausschnitt ein Cluster.
    @Test func zoomedOutGroupsNearbyIntoOneCluster() throws {
        let stations = try Self.fourTightQuadruplet()
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 52.530015, longitude: 13.440015),
            span: MKCoordinateSpan(latitudeDelta: 0.35, longitudeDelta: 0.35)
        )
        let items = StationMapClustering.annotationItems(for: stations, region: region)
        #expect(items.count == 1)
        guard case .cluster(let members, _) = items[0] else {
            Issue.record("Expected cluster")
            return
        }
        #expect(members.count == 4)
    }

    /// Gleiche Stationen — bei kleinem Ausschnitt Einzelpins (Gitter feiner als Abstände).
    @Test func zoomedInSplitsIntoIndividualPins() throws {
        let stations = try Self.fourTightQuadruplet()
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 52.530015, longitude: 13.440015),
            span: MKCoordinateSpan(latitudeDelta: 0.0012, longitudeDelta: 0.0012)
        )
        let items = StationMapClustering.annotationItems(for: stations, region: region)
        #expect(items.count == 4)
        let singles = items.compactMap { item -> Station? in
            if case .single(let station) = item { return station }
            return nil
        }
        #expect(singles.count == 4)
    }

    private static func fourTightQuadruplet() throws -> [Station] {
        let json = Data(
            """
            {"stations":[
              {"id":"AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEE0001","name":"S1","brand":"T","street":"a","place":"B","lat":52.53000,"lng":13.44000,"dist":1,"diesel":1.1,"e5":1.2,"e10":1.15,"isOpen":true,"houseNumber":"1","postCode":10115},
              {"id":"AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEE0002","name":"S2","brand":"T","street":"a","place":"B","lat":52.53003,"lng":13.44000,"dist":1,"diesel":1.1,"e5":1.2,"e10":1.15,"isOpen":true,"houseNumber":"1","postCode":10115},
              {"id":"AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEE0003","name":"S3","brand":"T","street":"a","place":"B","lat":52.53000,"lng":13.44003,"dist":1,"diesel":1.1,"e5":1.2,"e10":1.15,"isOpen":true,"houseNumber":"1","postCode":10115},
              {"id":"AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEE0004","name":"S4","brand":"T","street":"a","place":"B","lat":52.53003,"lng":13.44003,"dist":1,"diesel":1.1,"e5":1.2,"e10":1.15,"isOpen":true,"houseNumber":"1","postCode":10115}
            ]}
            """.utf8
        )
        return try JSONDecoder().decode(StationListEnvelope.self, from: json).stations
    }
}
