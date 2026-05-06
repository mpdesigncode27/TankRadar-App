import CoreLocation
import Foundation
import Testing
@testable import FuelNow

struct StationCarPlayPOIMapperTests {
    @Test("Maximal 12 Zeilen für CPPointOfInterestTemplate")
    func capsAtTwelveRows() throws {
        let stations = try decodeManyStationLines(count: 20)
        let rows = StationCarPlayPOIMapper.buildRows(stations: stations, preferredFuel: .e10)
        #expect(rows.count == StationCarPlayPOIMapper.maxPointsOfInterest)
        #expect(rows.map(\.stationID) == stations.prefix(12).map(\.id))
    }

    @Test("Picker-Titel bevorzugt Marke, sonst Stationsname")
    func pickerTitleUsesBrandOrName() throws {
        let withBrand = try decodeStation(
            """
            {"id":"11111111-1111-1111-1111-111111111111","name":"TOTAL BERLIN","brand":"TOTAL","street":"X","place":"BERLIN","lat":52.5,"lng":13.4,"dist":1.0,"diesel":1.5,"e5":1.6,"e10":1.55,"isOpen":true,"houseNumber":"1","postCode":10407}
            """
        )
        let rowBrand = StationCarPlayPOIMapper.makeRow(station: withBrand, preferredFuel: .diesel)
        #expect(rowBrand.pickerTitle == "TOTAL")

        let noBrand = try decodeStation(
            """
            {"id":"22222222-2222-2222-2222-222222222222","name":"Freie Tankstelle","brand":"   ","street":"Y","place":"BERLIN","lat":52.5,"lng":13.4,"dist":2.0,"diesel":1.4,"e5":null,"e10":null,"isOpen":false,"houseNumber":"","postCode":10407}
            """
        )
        let rowName = StationCarPlayPOIMapper.makeRow(station: noBrand, preferredFuel: .e10)
        #expect(rowName.pickerTitle == "Freie Tankstelle")
    }

    @Test("Detail-Zusammenfassung enthält Adresse und Kraftstoffzeile")
    func detailSummaryIncludesAddressAndFuels() throws {
        let station = try decodeStation(
            """
            {"id":"33333333-3333-3333-3333-333333333333","name":"Shell Example","brand":"Shell","street":"Musterstr.","place":"Berlin","lat":52.51,"lng":13.39,"dist":0.5,"diesel":1.799,"e5":1.899,"e10":1.849,"isOpen":true,"houseNumber":"10","postCode":10115}
            """
        )
        let row = StationCarPlayPOIMapper.makeRow(station: station, preferredFuel: .e10)
        #expect(row.detailSummary.contains("Musterstr."))
        #expect(row.detailSummary.contains("10115"))
        let line = StationCarPlayPOIMapper.compactFuelLine(station: station)
        #expect(line.contains("E10"))
    }

    private func decodeStation(_ jsonLine: String) throws -> Station {
        let data = Data(jsonLine.utf8)
        return try JSONDecoder().decode(Station.self, from: data)
    }

    private func decodeManyStationLines(count: Int) throws -> [Station] {
        var result: [Station] = []
        for index in 0 ..< count {
            let id = UUID()
            let json = """
            {"id":"\(id.uuidString)","name":"Station \(index)","brand":"Brand\(index)","street":"S","place":"P","lat":52.5,"lng":13.4,"dist":\(Double(index)),"diesel":1.5,"e5":1.6,"e10":1.55,"isOpen":true,"houseNumber":"1","postCode":10407}
            """
            result.append(try decodeStation(json))
        }
        return result
    }
}
