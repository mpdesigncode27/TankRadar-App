import Foundation

/// Entscheidet zwischen Live-Tankerkönig und Bund-Mock — siehe `makeDefault()`.
@MainActor
enum StationStoreFactory {
    /// **Mock erzwingen:** Scheme → Run → Environment → `FUELNOW_USE_MOCK_STATIONS` = `1`
    ///
    /// **Live erzwingen:** `FUELNOW_USE_LIVE_STATIONS` = `1` (z. B. Live-API auf dem Simulator oder Fehlerpfad testen).
    ///
    /// **Simulator (Debug und Release):** Standard ist **Mock**, damit ein ungültiger/deaktivierter Tankerkönig-Key nicht zu einer leeren Karte führt (Live: `FUELNOW_USE_LIVE_STATIONS=1`).
    ///
    /// **Gerät, Release:** Live, sobald ein gültiger Tankerkönig-Key gesetzt ist; sonst Mock (keine Platzhalter-Anfragen). **Gerät, Debug:** ohne gültigen Key → Mock (siehe `APIKeys`).
    static func makeDefault() -> StationStore {
        let env = ProcessInfo.processInfo.environment

        if env["FUELNOW_USE_MOCK_STATIONS"] == "1" {
            logMock(reason: "FUELNOW_USE_MOCK_STATIONS=1")
            return StationStore(fetcher: BundledMockStationFetcher())
        }

        if env["FUELNOW_USE_LIVE_STATIONS"] == "1" {
            logLive(reason: "FUELNOW_USE_LIVE_STATIONS=1")
            return StationStore()
        }

        #if targetEnvironment(simulator)
        logMock(reason: "Simulator — Standard-Mock (Live erzwingen: FUELNOW_USE_LIVE_STATIONS=1)")
        return StationStore(fetcher: BundledMockStationFetcher())
        #endif

        #if DEBUG
        if !isConfiguredTankerkoenigKey {
            logMock(reason: "DEBUG ohne gültigen Tankerkönig-Key (siehe APIKeys.example.swift)")
            return StationStore(fetcher: BundledMockStationFetcher())
        }
        #endif

        #if !DEBUG && !targetEnvironment(simulator)
        if !isConfiguredTankerkoenigKey {
            print(
                "FuelNow: Mock-Tankstellen aktiv — Release auf Gerät ohne gültigen Tankerkönig-Key (Platzhalter oder leer). Daten: MockData/mock-stations.json — siehe TAN-72."
            )
            return StationStore(fetcher: BundledMockStationFetcher())
        }
        #endif

        return StationStore()
    }

    private static var isConfiguredTankerkoenigKey: Bool {
        APIKeys.isTankerkoenigKeyConfiguredForRequests
    }

    private static func logMock(reason: String) {
        print("FuelNow: Mock-Tankstellen aktiv — \(reason). Daten: MockData/mock-stations.json")
    }

    private static func logLive(reason: String) {
        print("FuelNow: Live Tankerkönig — \(reason)")
    }
}
