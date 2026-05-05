import Foundation
import Testing
@testable import FuelNow

struct FuelTypePresentationTests {
    @Test func everyFuelTypeHasASymbol() {
        for fuel in FuelType.allCases {
            #expect(!fuel.settingsCardSymbolName.isEmpty)
        }
    }

    @Test func subtitleKeysAreFuelSpecificAndUseSettingsNamespace() {
        let keys = FuelType.allCases.map { $0.settingsCardSubtitleKey.key }
        #expect(Set(keys).count == FuelType.allCases.count)
        for key in keys {
            #expect(key.hasPrefix("settings.fuel.card."), "Expected subtitle key to use the settings.fuel.card.* namespace, got \(key).")
        }
    }

    @Test func e10MapsToLeafGlyph() {
        #expect(FuelType.e10.settingsCardSymbolName == "leaf.fill")
    }

    @Test func dieselMapsToFuelpumpCircle() {
        #expect(FuelType.diesel.settingsCardSymbolName == "fuelpump.circle.fill")
    }

    @Test func e5MapsToFuelpumpFill() {
        #expect(FuelType.e5.settingsCardSymbolName == "fuelpump.fill")
    }
}
