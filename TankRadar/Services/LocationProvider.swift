import Foundation

/// Standortbeschaffung für App Intents: zuerst **UserDefaults-Cache** (~2 min TTL), sonst **One-Shot-GPS**.
///
/// **Koordination mit ``LocationService``:** Die Karte schreibt bei jedem gültigen Live-Update denselben Cache
/// über ``UserDefaultsLocationSnapshotStore`` (siehe `TankRadarApp`). So bleiben Intents ohne Vordergrund-App
/// mit einem frischen letzten Standort versorgt; Cache-Miss löst einmalig `requestLocation()` aus.
actor LocationProvider {
    static let defaultTTL: TimeInterval = 120

    private let store: any LocationSnapshotStore
    private let ttl: TimeInterval
    private let clock: @Sendable () -> Date
    private let oneShot: any OneShotLocationFetching

    init(
        store: any LocationSnapshotStore = UserDefaultsLocationSnapshotStore(),
        ttl: TimeInterval = LocationProvider.defaultTTL,
        clock: @escaping @Sendable () -> Date = Date.init,
        oneShot: any OneShotLocationFetching = MainActorOneShotLocationFetcher()
    ) {
        self.store = store
        self.ttl = ttl
        self.clock = clock
        self.oneShot = oneShot
    }

    func resolvedSnapshot() async throws -> LocationSnapshot {
        let now = clock()
        if let cached = store.loadValid(referenceDate: now, ttl: ttl) {
            return cached
        }
        let fresh = try await oneShot.fetchSnapshot()
        store.save(fresh)
        return fresh
    }
}
