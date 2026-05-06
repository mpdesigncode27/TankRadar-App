import CoreLocation
import Foundation
import Observation

/// Anzeige-Zustand für die nächste UI-Schicht (ohne direktes `Error`-Equatable-Problem).
enum StationLoadState: Equatable {
    case idle
    case loading
    case loaded
    case failed(message: String)
}

/// Auslöser eines Abrufs — steuert, welche Debounce-Basis nach Erfolg/Fehler aktualisiert wird.
///
/// „Gebiet suchen“ (`forcedMapRegion`) ändert **nicht** die GPS-Debounce-Referenz: sonst würde der
/// nächste Standort-Callback (Karte noch am gewählten Ort) sofort wieder um die aktuelle Position
/// laden und alle Pins außerhalb der sichtbaren Region verschwinden lassen.
enum StationFetchTrigger: Sendable {
    case locationUpdate
    case forcedUserLocation
    case forcedMapRegion
}

/// Orchestriert Tankstellen-Ladevorgänge mit Debounce gegen GPS-Jitter und API-Rate-Limits.
///
/// **Debounce (GPS):** `handleLocationUpdate` vergleicht nur mit dem letzten **standortbezogenen**
/// Abruf — nicht mit einer nur kartenzentrierten Suche (`forcedMapRegion`).
///
/// Ein neuer standortbezogener Fetch startet nur, wenn `force == true` oder seit dem letzten solchen
/// Versuch mindestens ca. 30 s vergangen sind **oder** der Standort sich um mindestens ca. 500 m
/// zur letzten **GPS-Referenz** bewegt hat.
///
/// **Race / Cancellation:** Jeder neue Fetch bricht den vorherigen `Task` ab; Ergebnisse werden nur
/// übernommen, wenn der zugehörige Task nicht cancelled wurde (ältere Antworten ignorieren).
@MainActor
@Observable
final class StationStore {
    private(set) var stations: [Station] = []
    private(set) var loadState: StationLoadState = .idle
    /// Letzter Fehler für UI/Debug (z. B. `LocalizedError`); bei Erfolg `nil`.
    private(set) var lastError: Error?

    private let queryService: QueryService
    private let clock: () -> Date
    private let minimumDisplacementMeters: Double
    private let minimumFetchInterval: TimeInterval

    /// Mittelpunkt des letzten `list.php`-Aufrufs (für „In diesem Gebiet suchen“ / letzte Daten).
    private var lastFetchReference: CLLocation?
    private var lastFetchFinishedAt: Date?
    /// Bezug nur für `handleLocationUpdate`-Debounce (unabhängig von kartenzentrierter Suche).
    private var lastLocationLedFetchReference: CLLocation?
    private var lastLocationLedFetchFinishedAt: Date?
    /// Abbruch aus `deinit`; nicht vom Observation-Macro tracken lassen.
    @ObservationIgnored
    nonisolated(unsafe) private var fetchTask: Task<Void, Never>?

    init(
        fetcher: any StationFetching,
        clock: @escaping () -> Date = { Date() },
        minimumDisplacementMeters: Double = 500,
        minimumFetchInterval: TimeInterval = 30
    ) {
        self.queryService = QueryService(fetcher: fetcher)
        self.clock = clock
        self.minimumDisplacementMeters = minimumDisplacementMeters
        self.minimumFetchInterval = minimumFetchInterval
    }

    convenience init(tankerkoenigClient: TankerkoenigClient = TankerkoenigClient()) {
        self.init(fetcher: TankerkoenigStationFetcher(client: tankerkoenigClient))
    }

    /// Mittelpunkt des letzten abgeschlossenen `list.php`-Abrufs (Erfolg oder Fehler). `nil`, bis ein erster Versuch beendet ist.
    var lastFetchCenter: CLLocationCoordinate2D? {
        lastFetchReference?.coordinate
    }

    deinit {
        fetchTask?.cancel()
    }

    /// Verarbeitet einen Standort aus `LocationService` o. Ä. Wendet Debounce an, außer `force`.
    func handleLocationUpdate(_ location: CLLocation, radiusKm: Double = 5, force: Bool = false) {
        guard passesDebounce(location: location, force: force) else { return }
        scheduleFetch(location: location, radiusKm: radiusKm, trigger: .locationUpdate)
    }

    /// Ignoriert Debounce und startet sofort einen Fetch.
    /// - Standort-Refresh / Retry: `forcedUserLocation` (Standard).
    /// - „In diesem Gebiet suchen“: `forcedMapRegion` — GPS-Debounce-Basis bleibt unverändert.
    func forceRefresh(
        using location: CLLocation,
        radiusKm: Double = 5,
        trigger: StationFetchTrigger = .forcedUserLocation
    ) {
        scheduleFetch(location: location, radiusKm: radiusKm, trigger: trigger)
    }

    func cancelPendingFetch() {
        fetchTask?.cancel()
        fetchTask = nil
        if case .loading = loadState {
            loadState = stations.isEmpty ? .idle : .loaded
        }
    }

    // MARK: - Debounce

    func passesDebounce(location: CLLocation, force: Bool) -> Bool {
        if force { return true }
        guard let reference = lastLocationLedFetchReference, let finished = lastLocationLedFetchFinishedAt else {
            return true
        }
        let now = clock()
        let moved = location.distance(from: reference) >= minimumDisplacementMeters
        let waited = now.timeIntervalSince(finished) >= minimumFetchInterval
        return moved || waited
    }

    // MARK: - Fetch

    private func scheduleFetch(location: CLLocation, radiusKm: Double, trigger: StationFetchTrigger) {
        fetchTask?.cancel()

        let lat = location.coordinate.latitude
        let lng = location.coordinate.longitude
        let capturedLocation = location
        let capturedTrigger = trigger

        loadState = .loading
        lastError = nil

        fetchTask = Task { [weak self] in
            guard let self else { return }
            do {
                let list = try await queryService.fetchStationsSortedByDistance(latitude: lat, longitude: lng, radiusKm: radiusKm)
                try Task.checkCancellation()
                self.applySuccess(list, reference: capturedLocation, trigger: capturedTrigger)
            } catch is CancellationError {
                // Kein Throttling-State aktualisieren — der nächste gültige Fetch darf wieder starten.
            } catch {
                try? Task.checkCancellation()
                self.applyFailure(error, reference: capturedLocation, trigger: capturedTrigger)
            }
        }
    }

    private func applySuccess(_ list: [Station], reference: CLLocation, trigger: StationFetchTrigger) {
        guard !Task.isCancelled else { return }
        stations = list
        loadState = .loaded
        lastError = nil
        lastFetchReference = reference
        lastFetchFinishedAt = clock()
        if trigger.updatesLocationDebounceBaseline {
            lastLocationLedFetchReference = reference
            lastLocationLedFetchFinishedAt = clock()
        }
    }

    private func applyFailure(_ error: Error, reference: CLLocation, trigger: StationFetchTrigger) {
        guard !Task.isCancelled else { return }
        lastError = error
        let message = (error as? LocalizedError)?.errorDescription ?? String(describing: error)
        loadState = .failed(message: message)
        lastFetchReference = reference
        lastFetchFinishedAt = clock()
        if trigger.updatesLocationDebounceBaseline {
            lastLocationLedFetchReference = reference
            lastLocationLedFetchFinishedAt = clock()
        }
    }
}

private extension StationFetchTrigger {
    var updatesLocationDebounceBaseline: Bool {
        switch self {
        case .locationUpdate, .forcedUserLocation:
            true
        case .forcedMapRegion:
            false
        }
    }
}
