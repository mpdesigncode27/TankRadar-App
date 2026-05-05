import CoreLocation
import Foundation
import Testing
@testable import FuelNow

struct MockLocationStreamProvider: LocationStreamProviding {
    let events: [LocationStreamEvent]
    let throwsError: Error?

    init(events: [LocationStreamEvent], throwsError: Error? = nil) {
        self.events = events
        self.throwsError = throwsError
    }

    func makeStream() -> AsyncThrowingStream<LocationStreamEvent, Error> {
        AsyncThrowingStream { continuation in
            Task {
                if let throwsError {
                    continuation.finish(throwing: throwsError)
                    return
                }
                for event in events {
                    try? await Task.sleep(for: .milliseconds(5))
                    continuation.yield(event)
                }
                continuation.finish()
            }
        }
    }
}

/// Zählt, wie oft ``makeStream()`` aufgerufen wurde — Beweis für Auto-Restart in TAN-79.
final class CountingLocationStreamProvider: LocationStreamProviding, @unchecked Sendable {
    private let lock = NSLock()
    private var _streamCount = 0
    private let events: [LocationStreamEvent]

    init(events: [LocationStreamEvent] = []) {
        self.events = events
    }

    var streamCount: Int {
        lock.lock(); defer { lock.unlock() }
        return _streamCount
    }

    func makeStream() -> AsyncThrowingStream<LocationStreamEvent, Error> {
        lock.lock(); _streamCount += 1; lock.unlock()
        let events = self.events
        return AsyncThrowingStream { continuation in
            Task {
                for event in events {
                    try? await Task.sleep(for: .milliseconds(5))
                    continuation.yield(event)
                }
                continuation.finish()
            }
        }
    }
}

@Suite(.serialized)
struct LocationServiceTests {
    @Test @MainActor
    func deliversMockedLocations() async throws {
        let mock = MockLocationStreamProvider(events: [
            LocationStreamEvent(latitude: 52.5, longitude: 13.4, horizontalAccuracy: 10),
        ])
        let service = LocationService(
            streamProvider: mock,
            authorizationProvider: { .authorizedWhenInUse }
        )
        service.start()
        try await Task.sleep(for: .milliseconds(150))
        #expect(service.currentLocation?.coordinate.latitude == 52.5)
        #expect(service.currentLocation?.coordinate.longitude == 13.4)
        #expect(service.authorizationStatus == .authorizedWhenInUse)
        service.stop()
    }

    @Test @MainActor
    func persistsSnapshotsWhenSnapshotStoreConfigured() async throws {
        let suiteName = "test.loc.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = UserDefaultsLocationSnapshotStore(defaults: defaults)
        let mock = MockLocationStreamProvider(events: [
            LocationStreamEvent(latitude: 52.52, longitude: 13.405, horizontalAccuracy: 11),
        ])
        let service = LocationService(
            streamProvider: mock,
            authorizationProvider: { .authorizedWhenInUse },
            snapshotStore: store
        )
        service.start()
        try await Task.sleep(for: .milliseconds(150))
        let cached = store.loadValid(referenceDate: Date(), ttl: LocationProvider.defaultTTL)
        #expect(cached?.latitude == 52.52)
        #expect(cached?.longitude == 13.405)
        service.stop()
    }

    @Test @MainActor
    func refreshAuthorizationStatusReadsProviderAgain() {
        var status: CLAuthorizationStatus = .denied
        let service = LocationService(
            streamProvider: MockLocationStreamProvider(events: []),
            authorizationProvider: { status }
        )
        #expect(service.authorizationStatus == .denied)
        status = .authorizedWhenInUse
        service.refreshAuthorizationStatus()
        #expect(service.authorizationStatus == .authorizedWhenInUse)
    }

    @Test @MainActor
    func recordsStreamErrors() async throws {
        struct FakeError: Error {}
        let mock = MockLocationStreamProvider(events: [], throwsError: FakeError())
        let service = LocationService(streamProvider: mock, authorizationProvider: { .notDetermined })
        service.start()
        try await Task.sleep(for: .milliseconds(100))
        #expect(service.lastError is FakeError)
        service.stop()
    }

    /// TAN-79: Sobald die Authorization von `.notDetermined` auf `.authorizedWhenInUse` wechselt,
    /// muss der Live-Updates-Stream **automatisch** neu gestartet werden — sonst bleibt der blaue
    /// „Mein Standort"-Marker auch nach erteilter Permission unsichtbar (App-Restart wäre nötig).
    @Test @MainActor
    func handleAuthorizationChangeRestartsStreamWhenPermissionGranted() async throws {
        let provider = CountingLocationStreamProvider(events: [
            LocationStreamEvent(latitude: 52.5, longitude: 13.4, horizontalAccuracy: 8),
        ])
        let service = LocationService(
            streamProvider: provider,
            authorizationProvider: { .notDetermined }
        )
        service.start()
        try await Task.sleep(for: .milliseconds(150))
        let countAfterFirstStart = provider.streamCount
        #expect(countAfterFirstStart >= 1)

        service.handleAuthorizationChange(.authorizedWhenInUse)
        try await Task.sleep(for: .milliseconds(300))

        #expect(provider.streamCount > countAfterFirstStart, "stream must be re-established after authorization grant")
        #expect(service.authorizationStatus == .authorizedWhenInUse)
        #expect(service.currentLocation?.coordinate.latitude == 52.5)
        service.stop()
    }

    /// TAN-79: Wechselt die Authorization von einem bereits autorisierten Status (`.authorizedWhenInUse`)
    /// auf einen anderen autorisierten Status (`.authorizedAlways`), darf der Stream **nicht**
    /// unnötig neu gestartet werden — verhindert flackernde UI und doppelte Netzwerk-Requests.
    @Test @MainActor
    func handleAuthorizationChangeDoesNotRestartIfAlreadyAuthorized() async throws {
        let provider = CountingLocationStreamProvider(events: [])
        let service = LocationService(
            streamProvider: provider,
            authorizationProvider: { .authorizedWhenInUse }
        )
        service.start()
        try await Task.sleep(for: .milliseconds(40))
        let countAfterFirstStart = provider.streamCount

        service.handleAuthorizationChange(.authorizedAlways)
        try await Task.sleep(for: .milliseconds(40))

        #expect(provider.streamCount == countAfterFirstStart)
        #expect(service.authorizationStatus == .authorizedAlways)
        service.stop()
    }

    /// TAN-79: `requestWhenInUseAuthorizationIfNeeded()` ist im Test-Init (ohne ``LocationAuthorizationCenter``)
    /// ein No-op und darf weder crashen noch den Status verändern.
    @Test @MainActor
    func requestWhenInUseAuthorizationIfNeededIsNoOpWithoutCenter() {
        let service = LocationService(
            streamProvider: MockLocationStreamProvider(events: []),
            authorizationProvider: { .notDetermined }
        )
        service.requestWhenInUseAuthorizationIfNeeded()
        #expect(service.authorizationStatus == .notDetermined)
    }

    /// TAN-79: Das `CLAuthorizationStatus`-Helper soll exakt für die beiden System-Status
    /// `.authorizedWhenInUse` und `.authorizedAlways` true sein — Anker für die Auto-Restart-Logik.
    @Test
    func isAuthorizedForFuelNowMatchesAuthorizedStates() {
        #expect(CLAuthorizationStatus.authorizedWhenInUse.isAuthorizedForFuelNow == true)
        #expect(CLAuthorizationStatus.authorizedAlways.isAuthorizedForFuelNow == true)
        #expect(CLAuthorizationStatus.notDetermined.isAuthorizedForFuelNow == false)
        #expect(CLAuthorizationStatus.denied.isAuthorizedForFuelNow == false)
        #expect(CLAuthorizationStatus.restricted.isAuthorizedForFuelNow == false)
    }
}
