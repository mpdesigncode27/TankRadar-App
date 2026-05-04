import Foundation

/// Kraftstoffsorten für FuelNow und die Tankerkönig-API.
///
/// API-Mapping (Tankerkönig `list.php` / `detail.php` / `prices.php`):
/// - Query-Parameter `type`: `"e5"`, `"e10"`, `"diesel"` oder `"all"`.
/// - JSON-Felder pro Station: `"e5"`, `"e10"`, `"diesel"` — Zahlen in Euro pro Liter, oder in `prices.php` booleschem `false`, wenn die Sorte nicht angeboten wird.
enum FuelType: String, CaseIterable, Codable, Identifiable, Sendable {
    case e5
    case e10
    case diesel

    var id: String { rawValue }

    /// Anzeigename für die UI (Deutsch).
    var displayName: String {
        switch self {
        case .e5: "Super E5"
        case .e10: "Super E10"
        case .diesel: "Diesel"
        }
    }

    /// Schlüssel wie in der Tankerkönig-JSON (identisch mit `rawValue`).
    var tankerkoenigJSONKey: String { rawValue }
}
