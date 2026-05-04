import Foundation

/// Entscheidet zwischen Live-Tankerkönig und Bund-Mock — siehe `makeDefault()`.
@MainActor
enum StationStoreFactory {
    /// **Mock erzwingen:** Scheme → Run → Environment → `TANKRADAR_USE_MOCK_STATIONS` = `1`
    ///
    /// **Live erzwingen:** `TANKRADAR_USE_LIVE_STATIONS` = `1` (z. B. Live-API auf dem Simulator oder Fehlerpfad testen).
    ///
    /// **Simulator (Debug und Release):** Standard ist **Mock**, damit ein ungültiger/deaktivierter Tankerkönig-Key nicht zu einer leeren Karte führt (Live: `TANKRADAR_USE_LIVE_STATIONS=1`).
    ///
    /// **Gerät, Release:** Live, sobald ein gültiger Tankerkönig-Key gesetzt ist; sonst Mock (keine Platzhalter-Anfragen). **Gerät, Debug:** ohne gültigen Key → Mock (siehe `APIKeys`).
    static func makeDefault() -> StationStore {
        let env = ProcessInfo.processInfo.environment

        if env["TANKRADAR_USE_MOCK_STATIONS"] == "1" {
            logMock(reason: "TANKRADAR_USE_MOCK_STATIONS=1")
            return StationStore(fetcher: BundledMockStationFetcher())
        }

        if env["TANKRADAR_USE_LIVE_STATIONS"] == "1" {
            #if DEBUG
            logLive(reason: "TANKRADAR_USE_LIVE_STATIONS=1")
            #endif
            return StationStore()
        }

        #if targetEnvironment(simulator)
        #if DEBUG
        logMock(reason: "Simulator — Standard-Mock (Live erzwingen: TANKRADAR_USE_LIVE_STATIONS=1)")
        #else
        print("TankRadar: Mock-Tankstellen aktiv — Release-Simulator (Live: TANKRADAR_USE_LIVE_STATIONS=1). Daten: MockData/mock-stations.json")
        #endif
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
                "TankRadar: Mock-Tankstellen aktiv — Release auf Gerät ohne gültigen Tankerkönig-Key (Platzhalter oder leer). Daten: MockData/mock-stations.json — siehe TAN-72."
            )
            return StationStore(fetcher: BundledMockStationFetcher())
        }
        #endif

        return StationStore()
    }

    private static var isConfiguredTankerkoenigKey: Bool {
        APIKeys.isTankerkoenigKeyConfiguredForRequests
    }

    #if DEBUG
    private static func logMock(reason: String) {
        print("TankRadar: Mock-Tankstellen aktiv — \(reason). Daten: MockData/mock-stations.json")
    }

    private static func logLive(reason: String) {
        print("TankRadar: Live Tankerkönig — \(reason)")
    }
    #endif
}
