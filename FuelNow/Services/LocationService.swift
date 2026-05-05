import CoreLocation
import Foundation
import Observation

/// Von `CLLocationUpdate` oder Tests geliefertes Ereignis (nur Sendable-Snapshots, keine Live-`CLLocation`-Referenz).
struct LocationStreamEvent: Sendable {
    let latitude: Double?
    let longitude: Double?
    let horizontalAccuracy: Double

    init(location: CLLocation?) {
        if let location {
            latitude = location.coordinate.latitude
            longitude = location.coordinate.longitude
            horizontalAccuracy = location.horizontalAccuracy
        } else {
            latitude = nil
            longitude = nil
            horizontalAccuracy = -1
        }
    }

    init(latitude: Double, longitude: Double, horizontalAccuracy: Double = 5) {
        self.latitude = latitude
        self.longitude = longitude
        self.horizontalAccuracy = horizontalAccuracy
    }

    fileprivate func makeLocation() -> CLLocation? {
        guard let latitude, let longitude, horizontalAccuracy >= 0 else { return nil }
        return CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            altitude: 0,
            horizontalAccuracy: horizontalAccuracy,
            verticalAccuracy: -1,
            timestamp: Date()
        )
    }
}

/// Abstraktion über `CLLocationUpdate.liveUpdates()`, damit Unit-Tests ohne Simulator-GPS auskommen.
protocol LocationStreamProviding: Sendable {
    func makeStream() -> AsyncThrowingStream<LocationStreamEvent, Error>
}

/// Produktive Quelle: iteriert `CLLocationUpdate.liveUpdates()` und liefert nur Standort-Snapshots.
struct LiveLocationStreamProvider: LocationStreamProviding {
    func makeStream() -> AsyncThrowingStream<LocationStreamEvent, Error> {
        AsyncThrowingStream { continuation in
            let iteratorTask = Task {
                do {
                    for try await update in CLLocationUpdate.liveUpdates() {
                        continuation.yield(LocationStreamEvent(location: update.location))
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { @Sendable _ in
                iteratorTask.cancel()
            }
        }
    }
}

extension CLAuthorizationStatus {
    /// `true` für `.authorizedWhenInUse` und `.authorizedAlways` — App darf den Standort nutzen.
    var isAuthorizedForFuelNow: Bool {
        self == .authorizedWhenInUse || self == .authorizedAlways
    }
}

/// Hält den iOS-`CLLocationManager` über die App-Laufzeit hinweg lebendig (TAN-79).
///
/// Eine Wegwerf-`CLLocationManager()`-Instanz für die Permission-Anfrage ist fragil — Apple verlangt
/// eine über die Anfrage hinaus gehaltene Instanz mit Delegate, sonst geht der System-Dialog/die
/// Antwort verloren. Diese Klasse dient als Adapter, damit ``LocationService`` reaktiv auf
/// Authorization-Wechsel reagieren kann (`locationManagerDidChangeAuthorization`).
@MainActor
final class LocationAuthorizationCenter: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var changeHandler: (@MainActor (CLAuthorizationStatus) -> Void)?

    override init() {
        super.init()
        manager.delegate = self
    }

    var currentStatus: CLAuthorizationStatus {
        manager.authorizationStatus
    }

    /// Beobachtet künftige Authorization-Wechsel. Liefert den aktuellen Status sofort einmal mit.
    func observeAuthorizationChanges(_ handler: @escaping @MainActor (CLAuthorizationStatus) -> Void) {
        changeHandler = handler
        handler(currentStatus)
    }

    /// Triggert den iOS-Permission-Dialog, wenn noch keine Entscheidung vorliegt. No-op sonst.
    func requestWhenInUseAuthorizationIfNeeded() {
        guard manager.authorizationStatus == .notDetermined else { return }
        manager.requestWhenInUseAuthorization()
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor [weak self] in
            self?.changeHandler?(status)
        }
    }
}

/// Live-Standort für die Karte. Optional `snapshotStore`: bei gesetztem Store wird jeder gültige Fix in
/// denselben UserDefaults-Cache geschrieben wie ``LocationProvider`` (App Intents / Siri, ~2 min TTL).
///
/// **Permission-Lifecycle (TAN-79):** Wird ohne expliziten `authorizationProvider` initialisiert,
/// hält der Service einen ``LocationAuthorizationCenter`` und startet ``start()`` automatisch neu,
/// sobald die Authorization von `.notDetermined` / `.denied` auf `.authorizedWhenInUse` /
/// `.authorizedAlways` wechselt — damit der „Mein Standort"-Marker ohne App-Restart erscheint.
@MainActor
@Observable
final class LocationService {
    private(set) var currentLocation: CLLocation?
    private(set) var authorizationStatus: CLAuthorizationStatus
    private(set) var lastError: Error?

    private let streamProvider: any LocationStreamProviding
    private let authorizationProvider: @MainActor () -> CLAuthorizationStatus
    private let snapshotStore: (any LocationSnapshotStore)?
    private let authorizationCenter: LocationAuthorizationCenter?

    private var updatesTask: Task<Void, Never>?

    /// Produktiver Init: hält einen ``LocationAuthorizationCenter`` und reagiert reaktiv auf
    /// iOS-Authorization-Wechsel (`CLLocationManagerDelegate`).
    convenience init(snapshotStore: (any LocationSnapshotStore)? = nil) {
        let center = LocationAuthorizationCenter()
        self.init(
            streamProvider: LiveLocationStreamProvider(),
            authorizationProvider: { @MainActor in center.currentStatus },
            snapshotStore: snapshotStore,
            authorizationCenter: center
        )
    }

    /// Test-/DI-Init: nimmt einen mockbaren `authorizationProvider` und optional einen
    /// ``LocationAuthorizationCenter`` (Produktion) oder `nil` (Tests).
    init(
        streamProvider: any LocationStreamProviding,
        authorizationProvider: @escaping @MainActor () -> CLAuthorizationStatus,
        snapshotStore: (any LocationSnapshotStore)? = nil,
        authorizationCenter: LocationAuthorizationCenter? = nil
    ) {
        self.streamProvider = streamProvider
        self.authorizationProvider = authorizationProvider
        self.snapshotStore = snapshotStore
        self.authorizationCenter = authorizationCenter
        authorizationStatus = authorizationProvider()
        authorizationCenter?.observeAuthorizationChanges { [weak self] status in
            self?.handleAuthorizationChange(status)
        }
    }

    /// Startet den Live-Updates-Consumer. Mehrfacher Aufruf bricht die vorherige Session ab.
    ///
    /// **Hinweis (TAN-79):** Der `authorizationStatus` wird hier bewusst **nicht** überschrieben —
    /// die wahre Quelle ist ``handleAuthorizationChange(_:)`` (vom ``LocationAuthorizationCenter``
    /// oder dem Test-Hook), sonst würde ein Re-`start()` direkt nach Permission-Grant den gerade
    /// gesetzten Status wieder zurücksetzen.
    func start() {
        stop()
        lastError = nil
        let provider = streamProvider
        updatesTask = Task { [weak self] in
            let stream = provider.makeStream()
            do {
                for try await event in stream {
                    if Task.isCancelled { break }
                    await MainActor.run { [weak self] in
                        self?.apply(event)
                    }
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.lastError = error
                }
            }
        }
    }

    func stop() {
        updatesTask?.cancel()
        updatesTask = nil
    }

    /// Aktualisiert den Berechtigungsstatus vom System (z. B. nach Rückkehr aus den iOS-Einstellungen).
    func refreshAuthorizationStatus() {
        handleAuthorizationChange(authorizationProvider())
    }

    /// Triggert den iOS-Permission-Dialog (nur bei `.notDetermined`); produktiv über den
    /// gehaltenen ``LocationAuthorizationCenter``. In Tests ohne Center: No-op.
    func requestWhenInUseAuthorizationIfNeeded() {
        authorizationCenter?.requestWhenInUseAuthorizationIfNeeded()
    }

    /// Reaktiver Authorization-Wechsel. Startet ``start()`` automatisch neu, wenn der User die
    /// Permission gerade erteilt hat (`.notDetermined` / `.denied` → `.authorizedWhenInUse` /
    /// `.authorizedAlways`) — damit der „Mein Standort"-Marker ohne App-Restart erscheint.
    /// Sichtbar für Tests, damit Auto-Restart ohne echten `CLLocationManager` simuliert werden kann.
    func handleAuthorizationChange(_ status: CLAuthorizationStatus) {
        let previouslyAuthorized = authorizationStatus.isAuthorizedForFuelNow
        authorizationStatus = status
        if !previouslyAuthorized && status.isAuthorizedForFuelNow {
            start()
        }
    }

    private func apply(_ event: LocationStreamEvent) {
        if let location = event.makeLocation() {
            currentLocation = location
            snapshotStore?.save(LocationSnapshot(location: location))
        }
        // Authorization wird reaktiv über `handleAuthorizationChange(_:)` gepflegt — kein Read aus
        // `authorizationProvider()` hier (sonst kollidiert der Re-`start()`-Pfad nach Permission-Grant).
    }
}
