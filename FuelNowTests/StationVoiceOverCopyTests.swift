import Testing

@testable import FuelNow

struct StationVoiceOverCopyTests {
    @Test func mapPinSummary_openWithPrice() {
        let s = StationVoiceOverCopy.mapPinSummary(
            stationName: "TOTAL BERLIN",
            isOpen: true,
            priceDisplay: "1,32 €",
            fuelDisplayName: "Super E10"
        )
        #expect(s.contains("TOTAL BERLIN"))
        #expect(s.contains("Geöffnet"))
        #expect(s.contains("1,32"))
        #expect(s.contains("€"))
        #expect(s.contains("Super E10"))
    }

    @Test func mapPinSummary_closedWithDash() {
        let s = StationVoiceOverCopy.mapPinSummary(
            stationName: "SHELL",
            isOpen: false,
            priceDisplay: "—",
            fuelDisplayName: "Diesel"
        )
        #expect(s.contains("Geschlossen"))
        #expect(s.contains("—"))
        #expect(s.contains("Diesel"))
    }

    @Test func detailPriceRow_preferredSuffix() {
        let s = StationVoiceOverCopy.detailPriceRow(
            fuelDisplayName: "Super E10",
            formattedPriceOrUnavailable: "1,32 €",
            isPreferred: true
        )
        #expect(s.hasSuffix("Aktuell in den Einstellungen gewählt."))
    }

    @Test func detailPriceRow_notPreferredNoSuffix() {
        let s = StationVoiceOverCopy.detailPriceRow(
            fuelDisplayName: "Diesel",
            formattedPriceOrUnavailable: "Kein Preis verfügbar",
            isPreferred: false
        )
        #expect(!s.contains("Aktuell in den Einstellungen"))
        #expect(s.contains("Kein Preis verfügbar"))
    }
}
