import AppIntents
import Foundation

/// Siri/Shortcuts-Darstellung einer Tankstelle; `id` entspricht dem Domänen-`Station.id`.
struct StationEntity: AppEntity {
    typealias DefaultQuery = StationQuery

    static var defaultQuery: StationQuery { StationQuery() }

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Tankstelle"
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: LocalizedStringResource(stringLiteral: title))
    }

    let id: Station.ID
    let title: String

    init(station: Station) {
        id = station.id
        title = station.name
    }

    init(id: Station.ID, title: String) {
        self.id = id
        self.title = title
    }
}
