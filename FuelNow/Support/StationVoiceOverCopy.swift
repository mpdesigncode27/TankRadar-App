import Foundation

/// Deutsche VoiceOver-Texte für Karten-Pins und Detail-Preiszeilen (TAN-20).
enum StationVoiceOverCopy {
    static func mapPinSummary(stationName: String, isOpen: Bool, priceDisplay: String, fuelDisplayName: String) -> String {
        let status = isOpen ? "Geöffnet" : "Geschlossen"
        return "\(stationName). \(status). \(priceDisplay) für \(fuelDisplayName)."
    }

    static func detailPriceRow(fuelDisplayName: String, formattedPriceOrUnavailable: String, isPreferred: Bool) -> String {
        let preferredPart = isPreferred ? " Aktuell in den Einstellungen gewählt." : ""
        return "\(fuelDisplayName). \(formattedPriceOrUnavailable).\(preferredPart)"
    }
}
