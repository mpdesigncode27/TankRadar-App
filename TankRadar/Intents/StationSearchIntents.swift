import AppIntents
import Foundation
import SwiftUI

// MARK: - Find nearest

/// Siri/Kurzbefehle: geografisch nächste Tankstelle im eingestellten Suchradius.
struct FindNearestStationIntent: AppIntent {
    static var title: LocalizedStringResource { "Nächste Tankstelle" }

    static var description: IntentDescription {
        IntentDescription("Sucht die nächste Tankstelle um deinen Standort im aktuellen Suchradius.")
    }

    static var openAppWhenRun: Bool { false }

    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        do {
            guard let pair = try await StationIntentLookup.shared.findNearestStation() else {
                let message = "Keine Tankstelle im Suchradius gefunden."
                return .result(
                    dialog: IntentDialog(LocalizedStringResource(stringLiteral: message)),
                    view: StationIntentSnippetView(title: "TankRadar", subtitle: message)
                )
            }
            let station = pair.station
            let origin = pair.origin
            let km = QueryService.distanceKilometers(
                fromOriginLatitude: origin.latitude,
                originLng: origin.longitude,
                to: station
            )
            let subtitle = String(format: "%.1f km · %@", km, station.fullAddress)
            let dialogText = "Die nächste Tankstelle ist \(station.name)."
            return .result(
                dialog: IntentDialog(LocalizedStringResource(stringLiteral: dialogText)),
                view: StationIntentSnippetView(title: station.name, subtitle: subtitle)
            )
        } catch LocationProviderError.notAuthorized {
            let message = "TankRadar hat keinen Zugriff auf den Standort."
            return .result(
                dialog: IntentDialog(LocalizedStringResource(stringLiteral: message)),
                view: StationIntentSnippetView(title: "Standort", subtitle: "Bitte Ortung in den iOS-Einstellungen erlauben.")
            )
        } catch let failure as TankerkoenigClient.Failure {
            let message = failure.localizedDescription
            return .result(
                dialog: IntentDialog(LocalizedStringResource(stringLiteral: message)),
                view: StationIntentSnippetView(title: "TankRadar", subtitle: message)
            )
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? String(describing: error)
            return .result(
                dialog: IntentDialog(LocalizedStringResource(stringLiteral: message)),
                view: StationIntentSnippetView(title: "TankRadar", subtitle: message)
            )
        }
    }
}

// MARK: - Find cheapest

/// Siri/Kurzbefehle: günstigste Tankstelle für eine Sorte; ohne Parameter wie in den App-Einstellungen.
struct FindCheapestStationIntent: AppIntent {
    static var title: LocalizedStringResource { "Günstigste Tankstelle" }

    static var description: IntentDescription {
        IntentDescription("Sucht die günstigste Tankstelle für eine Kraftstoffsorte. Ohne Auswahl nutzt TankRadar deine Standard-Spritart.")
    }

    static var openAppWhenRun: Bool { false }

    @Parameter(title: "Kraftstoff")
    var fuel: FuelType?

    init() {}

    init(fuel: FuelType?) {
        self.fuel = fuel
    }

    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        do {
            guard let triple = try await StationIntentLookup.shared.findCheapestStation(explicitFuel: fuel) else {
                let message = "Keine Tankstelle mit Preis für diese Sorte im Suchradius."
                return .result(
                    dialog: IntentDialog(LocalizedStringResource(stringLiteral: message)),
                    view: StationIntentSnippetView(title: "TankRadar", subtitle: message)
                )
            }
            let station = triple.station
            let fuel = triple.fuel
            let origin = triple.origin
            guard let price = station.price(for: fuel) else {
                let message = "Kein Preis für \(fuel.displayName) verfügbar."
                return .result(
                    dialog: IntentDialog(LocalizedStringResource(stringLiteral: message)),
                    view: StationIntentSnippetView(title: station.name, subtitle: message)
                )
            }
            let km = QueryService.distanceKilometers(
                fromOriginLatitude: origin.latitude,
                originLng: origin.longitude,
                to: station
            )
            let priceText = Self.formatPriceEURPerLiter(price)
            let subtitle = "\(fuel.displayName): \(priceText) · \(String(format: "%.1f km", km))"
            let dialogText = "Die günstigste Tankstelle für \(fuel.displayName) ist \(station.name) für \(priceText)."
            return .result(
                dialog: IntentDialog(LocalizedStringResource(stringLiteral: dialogText)),
                view: StationIntentSnippetView(title: station.name, subtitle: subtitle)
            )
        } catch LocationProviderError.notAuthorized {
            let message = "TankRadar hat keinen Zugriff auf den Standort."
            return .result(
                dialog: IntentDialog(LocalizedStringResource(stringLiteral: message)),
                view: StationIntentSnippetView(title: "Standort", subtitle: "Bitte Ortung in den iOS-Einstellungen erlauben.")
            )
        } catch let failure as TankerkoenigClient.Failure {
            let message = failure.localizedDescription
            return .result(
                dialog: IntentDialog(LocalizedStringResource(stringLiteral: message)),
                view: StationIntentSnippetView(title: "TankRadar", subtitle: message)
            )
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? String(describing: error)
            return .result(
                dialog: IntentDialog(LocalizedStringResource(stringLiteral: message)),
                view: StationIntentSnippetView(title: "TankRadar", subtitle: message)
            )
        }
    }

    private static func formatPriceEURPerLiter(_ value: Double) -> String {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "de_DE")
        f.numberStyle = .decimal
        f.minimumFractionDigits = 3
        f.maximumFractionDigits = 3
        let num = f.string(from: NSNumber(value: value)) ?? String(format: "%.3f", value)
        return "\(num) €/l"
    }
}

// MARK: - Shortcuts

/// Kurzbefehle-Sätze (Deutsch); Siri kann Formulierungen variieren.
struct TankRadarAppShortcuts: AppShortcutsProvider {
    @AppShortcutsBuilder
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: FindNearestStationIntent(),
            phrases: [
                "Nächste Tankstelle in \(.applicationName)",
                "Wo ist die nächste Tankstelle in \(.applicationName)",
            ],
            shortTitle: "Nächste Tankstelle",
            systemImageName: "fuelpump.fill"
        )
        AppShortcut(
            intent: FindCheapestStationIntent(),
            phrases: [
                "Günstigste Tankstelle in \(.applicationName)",
                "Wo ist die günstigste Tankstelle in \(.applicationName)",
            ],
            shortTitle: "Günstigste Tankstelle",
            systemImageName: "eurosign.circle.fill"
        )
    }
}
