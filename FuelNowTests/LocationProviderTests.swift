import Foundation
import Testing

@testable import FuelNow

private enum StubError: Error {
    case unexpectedFetch
}

private actor MockOneShotFetcher: OneShotLocationFetching {
    private(set) var fetchCount = 0
    private let result: Result<LocationSnapshot, Error>

    init(result: Result<LocationSnapshot, Error>) {
        self.result = result
    }

    func fetchSnapshot() async throws -> LocationSnapshot {
        fetchCount += 1
        return try result.get()
    }
}

private final class MutableClock: @unchecked Sendable {
    var now: Date
    init(_ now: Date) {
        self.now = now
    }
}

struct LocationProviderTests {
    private func isolatedDefaults() -> (defaults: UserDefaults, suiteName: String) {
        let name = "test.TAN-49.\(UUID().uuidString)"
        return (UserDefaults(suiteName: name)!, name)
    }

    @Test func cacheHitWithinTTLSkipsOneShot() async throws {
        let (defaults, suiteName) = isolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = UserDefaultsLocationSnapshotStore(defaults: defaults)
        let anchor = Date(timeIntervalSince1970: 1_710_000_000)
        let recorded = anchor.addingTimeInterval(-60)
        store.save(LocationSnapshot(latitude: 52.5, longitude: 13.4, horizontalAccuracy: 12, recordedAt: recorded))
        let clock = MutableClock(anchor)
        let mock = MockOneShotFetcher(result: .failure(StubError.unexpectedFetch))
        let provider = LocationProvider(store: store, ttl: 120, clock: { clock.now }, oneShot: mock)
        let out = try await provider.resolvedSnapshot()
        #expect(out.latitude == 52.5)
        #expect(out.longitude == 13.4)
        #expect(await mock.fetchCount == 0)
    }

    @Test func cacheExpiredTriggersOneShot() async throws {
        let (defaults, suiteName) = isolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = UserDefaultsLocationSnapshotStore(defaults: defaults)
        let anchor = Date(timeIntervalSince1970: 1_711_000_000)
        let stale = anchor.addingTimeInterval(-121)
        store.save(LocationSnapshot(latitude: 0, longitude: 0, horizontalAccuracy: 10, recordedAt: stale))
        let clock = MutableClock(anchor)
        let fresh = LocationSnapshot(latitude: 52.1, longitude: 13.2, horizontalAccuracy: 8, recordedAt: anchor)
        let mock = MockOneShotFetcher(result: .success(fresh))
        let provider = LocationProvider(store: store, ttl: 120, clock: { clock.now }, oneShot: mock)
        let out = try await provider.resolvedSnapshot()
        #expect(out.latitude == 52.1)
        #expect(await mock.fetchCount == 1)
    }

    @Test func consecutiveCallsHitCacheAfterFirstFetch() async throws {
        let (defaults, suiteName) = isolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = UserDefaultsLocationSnapshotStore(defaults: defaults)
        let anchor = Date(timeIntervalSince1970: 1_712_000_000)
        let clock = MutableClock(anchor)
        let fresh = LocationSnapshot(latitude: 50, longitude: 8, horizontalAccuracy: 15, recordedAt: anchor)
        let mock = MockOneShotFetcher(result: .success(fresh))
        let provider = LocationProvider(store: store, ttl: 120, clock: { clock.now }, oneShot: mock)
        _ = try await provider.resolvedSnapshot()
        _ = try await provider.resolvedSnapshot()
        #expect(await mock.fetchCount == 1)
    }

    @Test func invalidAccuracyInDefaultsTreatedAsMiss() async throws {
        let (defaults, suiteName) = isolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(52.0, forKey: AppSettings.UserDefaultsKey.locationCacheLatitude)
        defaults.set(13.0, forKey: AppSettings.UserDefaultsKey.locationCacheLongitude)
        defaults.set(-5.0, forKey: AppSettings.UserDefaultsKey.locationCacheHorizontalAccuracy)
        defaults.set(Date().timeIntervalSince1970, forKey: AppSettings.UserDefaultsKey.locationCacheRecordedAt)
        let store = UserDefaultsLocationSnapshotStore(defaults: defaults)
        let anchor = Date(timeIntervalSince1970: 1_713_000_000)
        let clock = MutableClock(anchor)
        let fresh = LocationSnapshot(latitude: 51, longitude: 9, horizontalAccuracy: 10, recordedAt: anchor)
        let mock = MockOneShotFetcher(result: .success(fresh))
        let provider = LocationProvider(store: store, ttl: 120, clock: { clock.now }, oneShot: mock)
        _ = try await provider.resolvedSnapshot()
        #expect(await mock.fetchCount == 1)
    }
}
