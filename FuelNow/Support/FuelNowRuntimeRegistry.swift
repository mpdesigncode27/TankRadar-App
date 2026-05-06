import Foundation

/// Schwache Referenzen auf vom ``FuelNowApp`` gehaltene Singletons, damit die CarPlay-Scene dieselbe
/// ``StationStore``-/``LocationService``-Instanz wie die SwiftUI-Karte nutzen kann (TAN-55).
///
/// Wird beim ersten Erscheinen der Root-View gesetzt; bleibt für die App-Lebensdauer gültig.
@MainActor
enum FuelNowRuntimeRegistry {
    static weak var stationStore: StationStore?
    static weak var locationService: LocationService?
}
