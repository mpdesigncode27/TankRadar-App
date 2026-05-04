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

@MainActor
@Observable
final class LocationService {
    private(set) var currentLocation: CLLocation?
    private(set) var authorizationStatus: CLAuthorizationStatus
    private(set) var lastError: Error?

    private let streamProvider: any LocationStreamProviding
    private let authorizationProvider: @MainActor () -> CLAuthorizationStatus

    private var updatesTask: Task<Void, Never>?

    init(
        streamProvider: any LocationStreamProviding = LiveLocationStreamProvider(),
        authorizationProvider: @escaping @MainActor () -> CLAuthorizationStatus = { CLLocationManager().authorizationStatus }
    ) {
        self.streamProvider = streamProvider
        self.authorizationProvider = authorizationProvider
        authorizationStatus = authorizationProvider()
    }

    /// Startet den Live-Updates-Consumer. Mehrfacher Aufruf bricht die vorherige Session ab.
    func start() {
        stop()
        lastError = nil
        authorizationStatus = authorizationProvider()
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

    private func apply(_ event: LocationStreamEvent) {
        if let location = event.makeLocation() {
            currentLocation = location
        }
        authorizationStatus = authorizationProvider()
    }
}
