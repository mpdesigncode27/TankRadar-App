import Foundation
import Testing
@testable import FuelNow

struct AppSettingsTests {
    @Test func userDefaultsKeysMatchMapAndSettings() {
        #expect(AppSettings.UserDefaultsKey.preferredFuelType == "tr.preferredFuelType")
        // TAN-79: Key bleibt definiert (kein aktiver Reader mehr), wird aber nicht entfernt,
        // damit alte UserDefaults-Werte nicht verloren erscheinen.
        #expect(AppSettings.UserDefaultsKey.searchRadiusKm == "tr.searchRadiusKm")
        #expect(AppSettings.UserDefaultsKey.locationCacheLatitude == "tr.locationCache.latitude")
        #expect(AppSettings.UserDefaultsKey.locationCacheLongitude == "tr.locationCache.longitude")
        #expect(AppSettings.UserDefaultsKey.locationCacheHorizontalAccuracy == "tr.locationCache.horizontalAccuracy")
        #expect(AppSettings.UserDefaultsKey.locationCacheRecordedAt == "tr.locationCache.recordedAt")
        #expect(AppSettings.UserDefaultsKey.pendingMapStationFocusID == "tr.pendingMapStationFocusID")
        #expect(AppSettings.UserDefaultsKey.appearancePreference == "tr.appearancePreference")
    }

    @Test func searchRadiusIsLockedToTankerkoenigApiMaximum() {
        #expect(
            AppSettings.SearchRadius.apiMaxKm == 25,
            "Tankerkönig list.php erlaubt max. rad=25; siehe .cursor/skills/tankerkoenig-api/SKILL.md."
        )
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
