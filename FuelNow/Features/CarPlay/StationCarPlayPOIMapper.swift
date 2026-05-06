import CoreLocation
import Foundation
import MapKit

#if canImport(CarPlay)
import CarPlay
#endif

// MARK: - Presentation rows (unit-testable, kein CarPlay)

/// Eine Zeile für CarPlay POI-Liste und Map-Picker — gebaut aus ``Station`` + bevorzugter Kraftstoffsorte.
struct StationCarPlayPOIRow {
    let stationID: UUID
    let coordinate: CLLocationCoordinate2D
    /// Zeile im horizontalen Picker — typischerweise Marke.
    let pickerTitle: String
    /// Untertitel — bevorzugte Sorte + Preis (oder „—“).
    let pickerSubtitle: String
    /// Kurz-Zusammenfassung unter dem Picker-Eintrag — Status + Entfernung.
    let pickerSummary: String
    let detailTitle: String
    let detailSubtitle: String
    let detailSummary: String

    func makeMapItem() -> MKMapItem {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let item = MKMapItem(location: location, address: nil)
        item.name = detailTitle
        return item
    }
}

enum StationCarPlayPOIMapper {
    /// Tankerkönig / Produkt: höchstens 12 POIs laut `CPPointOfInterestTemplate`.
    static let maxPointsOfInterest = 12

    static func buildRows(stations: [Station], preferredFuel: FuelType) -> [StationCarPlayPOIRow] {
        Array(stations.prefix(maxPointsOfInterest)).map { makeRow(station: $0, preferredFuel: preferredFuel) }
    }

    static func makeRow(station: Station, preferredFuel: FuelType) -> StationCarPlayPOIRow {
        let brand = station.brand.trimmingCharacters(in: .whitespacesAndNewlines)
        let pickerTitle = brand.isEmpty ? station.name : brand

        let priceText: String
        if let euros = station.price(for: preferredFuel) {
            priceText = StationDisplayFormatting.priceString(euros: euros)
        } else {
            priceText = "—"
        }
        let pickerSubtitle = "\(preferredFuel.displayName) \(priceText)"

        let status = station.isOpen
            ? String(localized: "station.status.open")
            : String(localized: "station.status.closed")
        let distance = StationDisplayFormatting.distanceString(kilometers: station.distanceKilometers)
        let pickerSummary = "\(status) · \(distance)"

        let detailTitle = station.name
        let detailSubtitle = "\(status) · \(distance)"
        let detailSummary = """
        \(station.fullAddress)

        \(compactFuelLine(station: station))
        """

        return StationCarPlayPOIRow(
            stationID: station.id,
            coordinate: station.coordinate,
            pickerTitle: pickerTitle,
            pickerSubtitle: pickerSubtitle,
            pickerSummary: pickerSummary,
            detailTitle: detailTitle,
            detailSubtitle: detailSubtitle,
            detailSummary: detailSummary
        )
    }

    /// Eine kompakte Preiszeile für alle Sorten — konsistent mit der Detailansicht (2 Nachkommastellen).
    static func compactFuelLine(station: Station) -> String {
        FuelType.allCases.map { fuel in
            let label = fuel.displayName
            let value: String
            if let euros = station.price(for: fuel) {
                value = StationDisplayFormatting.priceString(euros: euros)
            } else {
                value = "—"
            }
            return "\(label) \(value)"
        }.joined(separator: " · ")
    }

    #if canImport(CarPlay)
    @MainActor
    static func makePointsOfInterest(rows: [StationCarPlayPOIRow], stationsByID: [UUID: Station]) -> [CPPointOfInterest] {
        rows.map { row in
            let poi = CPPointOfInterest(
                location: row.makeMapItem(),
                title: row.pickerTitle,
                subtitle: row.pickerSubtitle,
                summary: row.pickerSummary,
                detailTitle: row.detailTitle,
                detailSubtitle: row.detailSubtitle,
                detailSummary: row.detailSummary,
                pinImage: nil
            )
            poi.userInfo = row.stationID.uuidString as NSString
            if let station = stationsByID[row.stationID] {
                let navigateTitle = String(localized: "carplay.poi.navigateMaps")
                poi.primaryButton = CPTextButton(title: navigateTitle, textStyle: .normal) { _ in
                    CarPlayDrivingNavigation.openDrivingDirections(to: station)
                }
            }
            return poi
        }
    }

    /// Zweites Tab: sortierte Liste — dieselben Stationen wie die POI-Karte (kein zweites Datenmodell).
    @MainActor
    static func makeNearbyListTemplate(stations: [Station], preferredFuel: FuelType) -> CPListTemplate {
        let sliced = Array(stations.prefix(maxPointsOfInterest))
        let items: [CPListItem] = sliced.map { station in
            let row = makeRow(station: station, preferredFuel: preferredFuel)
            let item = CPListItem(text: row.pickerTitle, detailText: row.pickerSubtitle)
            item.handler = { _, completion in
                CarPlayDrivingNavigation.openDrivingDirections(to: station)
                completion()
            }
            return item
        }
        let section = CPListSection(items: items)
        return CPListTemplate(title: String(localized: "carplay.plus.list.title"), sections: [section])
    }

    @MainActor
    static func makePointsTemplate(
        points: [CPPointOfInterest],
        delegate: (any CPPointOfInterestTemplateDelegate)?
    ) -> CPPointOfInterestTemplate {
        let template = CPPointOfInterestTemplate(
            title: String(localized: "carplay.plus.map.title"),
            pointsOfInterest: points,
            selectedIndex: points.isEmpty ? 0 : 0
        )
        template.pointOfInterestDelegate = delegate
        return template
    }
    #endif
}
