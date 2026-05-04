import Foundation

/// Zentrale Auflösung von Tankstellen-IDs für Siri / Shortcuts. Standard: leer, bis QueryService oder ein Cache angebunden ist.
actor StationIntentResolution {
    static let shared = StationIntentResolution()

    private var resolver: any StationIntentResolving

    init(resolver: any StationIntentResolving = EmptyStationIntentResolver()) {
        self.resolver = resolver
    }

    func setResolver(_ resolver: any StationIntentResolving) {
        self.resolver = resolver
    }

    func stations(for ids: [Station.ID]) async throws -> [Station] {
        try await resolver.stations(for: ids)
    }
}
