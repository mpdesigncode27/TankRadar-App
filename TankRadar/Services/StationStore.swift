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

/// Orchestriert Tankstellen-Ladevorgänge mit Debounce gegen GPS-Jitter und API-Rate-Limits.
///
/// **Debounce:** Ein neuer Netzwerk-Fetch startet nur, wenn `force == true` oder seit dem
/// letzten **beendeten** Versuch mindestens ca. 30 s vergangen sind **oder** der Standort sich
/// um mindestens ca. 500 m zum letzten Referenzpunkt bewegt hat (gleicher Referenzpunkt wie beim letzten Versuch).
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

    private var lastFetchReference: CLLocation?
    private var lastFetchFinishedAt: Date?
    /// Abbruch aus `deinit` — nur von MainActor-Mutationen gesetzt; Zugriff aus `deinit` ist daher `nonisolated(unsafe)`.
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

    deinit {
        fetchTask?.cancel()
    }

    /// Verarbeitet einen Standort aus `LocationService` o. Ä. Wendet Debounce an, außer `force`.
    func handleLocationUpdate(_ location: CLLocation, radiusKm: Double = 5, force: Bool = false) {
        guard passesDebounce(location: location, force: force) else { return }
        scheduleFetch(location: location, radiusKm: radiusKm)
    }

    /// Ignoriert Debounce und startet sofort einen Fetch (Pull-to-refresh / „Aktualisieren“).
    func forceRefresh(using location: CLLocation, radiusKm: Double = 5) {
        scheduleFetch(location: location, radiusKm: radiusKm)
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
        guard let reference = lastFetchReference, let finished = lastFetchFinishedAt else {
            return true
        }
        let now = clock()
        let moved = location.distance(from: reference) >= minimumDisplacementMeters
        let waited = now.timeIntervalSince(finished) >= minimumFetchInterval
        return moved || waited
    }

    // MARK: - Fetch

    private func scheduleFetch(location: CLLocation, radiusKm: Double) {
        fetchTask?.cancel()

        let lat = location.coordinate.latitude
        let lng = location.coordinate.longitude
        let capturedLocation = location

        loadState = .loading
        lastError = nil

        fetchTask = Task { [weak self] in
            guard let self else { return }
            do {
                let list = try await queryService.fetchStationsSortedByDistance(latitude: lat, longitude: lng, radiusKm: radiusKm)
                try Task.checkCancellation()
                self.applySuccess(list, reference: capturedLocation)
            } catch is CancellationError {
                // Kein Throttling-State aktualisieren — der nächste gültige Fetch darf wieder starten.
            } catch {
                try? Task.checkCancellation()
                self.applyFailure(error, reference: capturedLocation)
            }
        }
    }

    private func applySuccess(_ list: [Station], reference: CLLocation) {
        guard !Task.isCancelled else { return }
        stations = list
        loadState = .loaded
        lastError = nil
        lastFetchReference = reference
        lastFetchFinishedAt = clock()
    }

    private func applyFailure(_ error: Error, reference: CLLocation) {
        guard !Task.isCancelled else { return }
        lastError = error
        let message = (error as? LocalizedError)?.errorDescription ?? String(describing: error)
        loadState = .failed(message: message)
        lastFetchReference = reference
        lastFetchFinishedAt = clock()
    }
}
