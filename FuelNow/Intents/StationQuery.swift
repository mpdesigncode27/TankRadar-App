import AppIntents
import Foundation

struct StationQuery: EntityQuery {
    func entities(for identifiers: [StationEntity.ID]) async throws -> [StationEntity] {
        let stations = try await StationIntentResolution.shared.stations(for: identifiers)
        let byID = Dictionary(uniqueKeysWithValues: stations.map { ($0.id, $0) })
        return identifiers.compactMap { id in
            byID[id].map { StationEntity(station: $0) }
        }
    }

    func suggestedEntities() async throws -> [StationEntity] {
        []
    }
}
