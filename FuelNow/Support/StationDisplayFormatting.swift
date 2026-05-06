import Foundation

/// Gemeinsame Preis- und Entfernungsformatierung für Tankstellen-UI (Karte, Detail, CarPlay).
///
/// Hält dieselbe EUR-/km-Darstellung wie zuvor in ``StationDetailView`` — Locale `de_DE`
/// für stabile Tankstellendarstellung in Deutschland (FuelNow-Zielregion).
enum StationDisplayFormatting {
    private static let eurosFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        formatter.locale = Locale(identifier: "de_DE")
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }()

    private static let distanceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        formatter.numberStyle = .decimal
        return formatter
    }()

    static func priceString(euros: Double) -> String {
        eurosFormatter.string(from: NSNumber(value: euros)) ?? String(format: "%.2f €", euros)
    }

    static func distanceString(kilometers: Double?) -> String {
        guard let kilometers else {
            return "—"
        }
        let formatted = distanceFormatter.string(from: NSNumber(value: kilometers)) ?? String(format: "%.1f", kilometers)
        return "ca. \(formatted) km"
    }
}
