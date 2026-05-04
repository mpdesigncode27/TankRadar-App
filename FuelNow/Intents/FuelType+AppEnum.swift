import AppIntents
import Foundation

extension FuelType: AppEnum {
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Kraftstoff"
    }

    /// Kurztitel für Siri/Shortcuts (entspricht `displayName` / Deutsch).
    static var caseDisplayRepresentations: [FuelType: DisplayRepresentation] {
        [
            .e5: "Super E5",
            .e10: "Super E10",
            .diesel: "Diesel",
        ]
    }
}
