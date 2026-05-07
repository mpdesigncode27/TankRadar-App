import Foundation

/// Entscheidet zwischen Live-Tankerkönig und QA-Mock — siehe `makeDefault()`.
///
/// **TAN-91:** Live ist ab jetzt **überall** Standard (Simulator + Gerät, Debug + Release).
/// Der frühere Berlin-Mock-Fallback (Simulator-Default und Release ohne Key) ist entfernt,
/// weil er reale Tankstellen vortäuschte. Bei fehlender Netzwerkverbindung erscheint stattdessen
/// ein Offline-Splash (`OfflineSplashView`); fehlende API-Keys / Server-Fehler bleiben im
/// bestehenden Error-Alert sichtbar.
@MainActor
enum StationStoreFactory {
    /// **Mock erzwingen (Tests / QA-Snapshots):** Scheme → Run → Environment →
    /// `FUELNOW_USE_MOCK_STATIONS` = `1`. Liefert `BundledMockStationFetcher` mit den
    /// Berliner Demo-Stationen aus `mock-stations.json`. **Nur** für UI-Tests / QA gedacht —
    /// **nie** als Default in normalen Builds.
    ///
    /// **Default überall:** Live-Tankerkönig (`StationStore()`). Ohne gültigen Key oder ohne
    /// Netzwerk zeigt die App den Offline-Splash bzw. den Error-Alert.
    static func makeDefault() -> StationStore {
        makeDefault(environment: ProcessInfo.processInfo.environment)
    }

    /// Test-Hook: erlaubt deterministisches Setzen der Env-Variablen ohne globalen
    /// `setenv`, damit parallele Testläufe sich nicht gegenseitig stören.
    static func makeDefault(environment env: [String: String]) -> StationStore {
        if env["FUELNOW_USE_MOCK_STATIONS"] == "1" {
            logMock(reason: "FUELNOW_USE_MOCK_STATIONS=1 (QA-Override)")
            return StationStore(fetcher: BundledMockStationFetcher())
        }

        logLive(reason: "Live-Default (TAN-91)")
        return StationStore()
    }

    private static func logMock(reason: String) {
        print("FuelNow: Mock-Tankstellen aktiv — \(reason). Daten: MockData/mock-stations.json")
    }

    private static func logLive(reason: String) {
        print("FuelNow: Live Tankerkönig — \(reason)")
    }
}
