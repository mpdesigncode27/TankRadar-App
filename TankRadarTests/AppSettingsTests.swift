import Foundation
import Testing
@testable import TankRadar

struct AppSettingsTests {
    @Test func userDefaultsKeysMatchMapAndSettings() {
        #expect(AppSettings.UserDefaultsKey.preferredFuelType == "tr.preferredFuelType")
        #expect(AppSettings.UserDefaultsKey.searchRadiusKm == "tr.searchRadiusKm")
        #expect(AppSettings.UserDefaultsKey.locationCacheLatitude == "tr.locationCache.latitude")
        #expect(AppSettings.UserDefaultsKey.locationCacheLongitude == "tr.locationCache.longitude")
        #expect(AppSettings.UserDefaultsKey.locationCacheHorizontalAccuracy == "tr.locationCache.horizontalAccuracy")
        #expect(AppSettings.UserDefaultsKey.locationCacheRecordedAt == "tr.locationCache.recordedAt")
        #expect(AppSettings.UserDefaultsKey.pendingMapStationFocusID == "tr.pendingMapStationFocusID")
        #expect(AppSettings.UserDefaultsKey.appearancePreference == "tr.appearancePreference")
    }

    @Test func searchRadiusBounds() {
        #expect(AppSettings.SearchRadius.minKm == 1)
        #expect(AppSettings.SearchRadius.maxKm == 25)
        #expect(AppSettings.SearchRadius.defaultKm == 5)
    }

    @Test(arguments: [
        (0.4, 1),
        (1.0, 1),
        (1.4, 1),
        (1.5, 2),
        (12.3, 12),
        (24.6, 25),
        (25.0, 25),
        (100.0, 25),
        (-5.0, 1),
    ])
    func clampedKmMatchesSliderPolicy(slider: Double, expectedKm: Int) {
        #expect(AppSettings.SearchRadius.clampedKm(sliderValue: slider) == expectedKm)
    }

    @Test func tankerkoenigAttributionURL() {
        let url = AppSettings.TankerkoenigAttribution.infoURL
        #expect(url.scheme == "https")
        #expect(url.host == "creativecommons.tankerkoenig.de")
    }

    @Test func preferredFuelRawValuesAreValidFuelTypes() {
        for fuel in FuelType.allCases {
            #expect(FuelType(rawValue: fuel.rawValue) == fuel)
        }
    }

    @Test func appearancePreferenceResolvedFallsBackToSystemForUnknownRaw() {
        #expect(AppSettings.AppearancePreference.resolved(storedRaw: "system") == .system)
        #expect(AppSettings.AppearancePreference.resolved(storedRaw: "light") == .light)
        #expect(AppSettings.AppearancePreference.resolved(storedRaw: "dark") == .dark)
        #expect(AppSettings.AppearancePreference.resolved(storedRaw: "") == .system)
        #expect(AppSettings.AppearancePreference.resolved(storedRaw: "bogus") == .system)
    }

    @Test func appearancePreferenceCaseIterableIsStable() {
        #expect(AppSettings.AppearancePreference.allCases.map(\.rawValue) == ["system", "light", "dark"])
    }
}
