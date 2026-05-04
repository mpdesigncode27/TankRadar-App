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

}
