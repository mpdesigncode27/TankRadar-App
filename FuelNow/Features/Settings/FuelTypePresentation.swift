import SwiftUI

/// UI-seitige Repräsentation einer `FuelType`-Sorte für die Karten-Auswahl in den Einstellungen.
///
/// Trennt View-spezifische Werte (SF-Symbol, Untertitel-Key) vom reinen Domain-Enum `FuelType`,
/// damit das Modell nicht von SwiftUI abhängig ist.
extension FuelType {
    /// SF-Symbol für die Karten-Glyph (HIG-konform, brand-frei).
    var settingsCardSymbolName: String {
        switch self {
        case .e5:
            "fuelpump.fill"
        case .e10:
            "leaf.fill"
        case .diesel:
            "fuelpump.circle.fill"
        }
    }

    /// 1-Zeilen-Erklärung als Lokalisierungs-Schlüssel; Strings liegen in `Localizable.xcstrings`.
    var settingsCardSubtitleKey: LocalizedStringResource {
        switch self {
        case .e5:
            "settings.fuel.card.e5.subtitle"
        case .e10:
            "settings.fuel.card.e10.subtitle"
        case .diesel:
            "settings.fuel.card.diesel.subtitle"
        }
    }
}
