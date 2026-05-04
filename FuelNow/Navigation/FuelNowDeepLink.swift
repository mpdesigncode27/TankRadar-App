import Foundation

/// Custom-URL-Schema `fuelnow://` für Karte und Tankstellen-Fokus (Phase 6).
enum FuelNowDeepLink: Equatable, Sendable {
    /// Nur Karte öffnen; ausstehende Fokus-ID wird verworfen.
    case map
    /// Konkrete Tankstelle auswählen, sobald sie im `StationStore` liegt.
    case station(UUID)

    /// Unterstützte Formen u. a. `fuelnow://map`, `fuelnow://station/<uuid>`, `fuelnow:///station/<uuid>`.
    static func parse(_ url: URL) -> FuelNowDeepLink? {
        guard url.scheme?.caseInsensitiveCompare("fuelnow") == .orderedSame else { return nil }

        let host = url.host?.lowercased() ?? ""
        let pathParts = url.path.split(separator: "/").map(String.init).filter { !$0.isEmpty }

        if host == "map", pathParts.isEmpty {
            return .map
        }

        if host.isEmpty, pathParts.count == 1, pathParts[0].lowercased() == "map" {
            return .map
        }

        if host == "station", let raw = pathParts.first, let uuid = UUID(uuidString: raw) {
            return .station(uuid)
        }

        if host.isEmpty, pathParts.count >= 2,
           pathParts[0].lowercased() == "station",
           let uuid = UUID(uuidString: pathParts[1]) {
            return .station(uuid)
        }

        return nil
    }
}
