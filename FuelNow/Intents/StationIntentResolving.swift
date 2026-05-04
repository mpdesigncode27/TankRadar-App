import Foundation

/// Liefert `Station`-Domänenmodelle für App-Intents (`StationQuery`). Die Hauptapp kann den Resolver später mit Cache / Store verdrahten.
protocol StationIntentResolving: Sendable {
    func stations(for ids: [Station.ID]) async throws -> [Station]
}

struct EmptyStationIntentResolver: StationIntentResolving {
    func stations(for ids: [Station.ID]) async throws -> [Station] {
        []
    }
}
