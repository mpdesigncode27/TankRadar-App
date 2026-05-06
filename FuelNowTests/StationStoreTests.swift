import CoreLocation
import Foundation
import Testing
@testable import FuelNow

private actor MockStationFetcher: StationFetching {
    private(set) var completedInvocationCount = 0
    private var sleepNanoseconds: UInt64 = 0
    private var result: Result<[Station], Error> = .success([])

    func configure(sleepNanoseconds: UInt64? = nil, result: Result<[Station], Error>? = nil) {
        if let sleepNanoseconds {
            self.sleepNanoseconds = sleepNanoseconds
        }
        if let result {
            self.result = result
        }
    }

    func fetchStations(latitude: Double, longitude: Double, radiusKm: Double) async throws -> [Station] {
        if sleepNanoseconds > 0 {
            try await Task.sleep(nanoseconds: sleepNanoseconds)
        }
        defer { completedInvocationCount += 1 }
        return try result.get()
    }
}

@Suite(.serialized)
@MainActor
struct StationStoreTests {
    private let referenceCoordinate = CLLocation(latitude: 52.5, longitude: 13.4)

    @Test func skipsFetchInsideTimeAndDistanceWindow() async throws {
        let fetcher = MockStationFetcher()
        let base = Date(timeIntervalSince1970: 1_700_000_000)
        var now = base
        let store = StationStore(fetcher: fetcher, clock: { now })

        store.handleLocationUpdate(referenceCoordinate, radiusKm: 5)
        try await Task.sleep(for: .milliseconds(80))
        #expect(await fetcher.completedInvocationCount == 1)

        let tinyMove = CLLocation(latitude: 52.50001, longitude: 13.4)
        store.handleLocationUpdate(tinyMove, radiusKm: 5)
        try await Task.sleep(for: .milliseconds(80))
        #expect(await fetcher.completedInvocationCount == 1)

        now = base.addingTimeInterval(31)
        store.handleLocationUpdate(tinyMove, radiusKm: 5)
        try await Task.sleep(for: .milliseconds(80))
        #expect(await fetcher.completedInvocationCount == 2)
    }

    @Test func largeMovementTriggersFetchBeforeIntervalElapsed() async throws {
        let fetcher = MockStationFetcher()
        let base = Date(timeIntervalSince1970: 1_700_000_000)
        let now = base
        let store = StationStore(fetcher: fetcher, clock: { now })

        store.handleLocationUpdate(referenceCoordinate, radiusKm: 5)
        try await Task.sleep(for: .milliseconds(80))
        #expect(await fetcher.completedInvocationCount == 1)

        let farNorth = CLLocation(latitude: 52.505, longitude: 13.4)
        store.handleLocationUpdate(farNorth, radiusKm: 5)
        try await Task.sleep(for: .milliseconds(80))
        #expect(await fetcher.completedInvocationCount == 2)
    }

    @Test func lastFetchCenterReflectsCompletedFetch() async throws {
        let fetcher = MockStationFetcher()
        let store = StationStore(fetcher: fetcher, clock: { Date() })
        #expect(store.lastFetchCenter == nil)

        store.forceRefresh(using: referenceCoordinate, radiusKm: 5)
        try await Task.sleep(for: .milliseconds(80))

        let center = try #require(store.lastFetchCenter)
        #expect(center.latitude == referenceCoordinate.coordinate.latitude)
        #expect(center.longitude == referenceCoordinate.coordinate.longitude)
    }

    @Test func mapRegionForceRefreshDoesNotResetLocationDebounce() async throws {
        let fetcher = MockStationFetcher()
        let base = Date(timeIntervalSince1970: 1_700_000_000)
        var now = base
        let store = StationStore(fetcher: fetcher, clock: { now })
        let userLoc = CLLocation(latitude: 52.5, longitude: 13.4)
        let mapCenterFar = CLLocation(latitude: 53.5, longitude: 13.4)

        store.handleLocationUpdate(userLoc, radiusKm: 5)
        try await Task.sleep(for: .milliseconds(80))
        #expect(await fetcher.completedInvocationCount == 1)

        store.forceRefresh(using: mapCenterFar, radiusKm: 5, trigger: .forcedMapRegion)
        try await Task.sleep(for: .milliseconds(80))
        #expect(await fetcher.completedInvocationCount == 2)

        let tinyJitter = CLLocation(latitude: 52.50001, longitude: 13.4)
        store.handleLocationUpdate(tinyJitter, radiusKm: 5)
        try await Task.sleep(for: .milliseconds(80))
        #expect(await fetcher.completedInvocationCount == 2)

        now = base.addingTimeInterval(31)
        store.handleLocationUpdate(tinyJitter, radiusKm: 5)
        try await Task.sleep(for: .milliseconds(80))
        #expect(await fetcher.completedInvocationCount == 3)
    }

    @Test func forceRefreshBypassesDebounce() async throws {
        let fetcher = MockStationFetcher()
        let base = Date(timeIntervalSince1970: 1_700_000_000)
        let now = base
        let store = StationStore(fetcher: fetcher, clock: { now })

        store.handleLocationUpdate(referenceCoordinate, radiusKm: 5)
        try await Task.sleep(for: .milliseconds(80))
        #expect(await fetcher.completedInvocationCount == 1)

        store.handleLocationUpdate(referenceCoordinate, radiusKm: 5)
        try await Task.sleep(for: .milliseconds(40))
        #expect(await fetcher.completedInvocationCount == 1)

        store.forceRefresh(using: referenceCoordinate, radiusKm: 5)
        try await Task.sleep(for: .milliseconds(80))
        #expect(await fetcher.completedInvocationCount == 2)
    }

    @Test func exposesFailureMessageAndLastError() async throws {
        struct Boom: Error {}
        let fetcher = MockStationFetcher()
        await fetcher.configure(result: .failure(Boom()))
        let store = StationStore(fetcher: fetcher, clock: { Date() })

        store.forceRefresh(using: referenceCoordinate, radiusKm: 5)
        try await Task.sleep(for: .milliseconds(80))

        guard case let .failed(message) = store.loadState else {
            Issue.record("Expected failed load state")
            return
        }
        #expect(!message.isEmpty)
        #expect(store.lastError is Boom)
    }

    @Test func newFetchCancelsSlowInFlightRequest() async throws {
        let fetcher = MockStationFetcher()
        await fetcher.configure(sleepNanoseconds: 400_000_000)
        let store = StationStore(fetcher: fetcher, clock: { Date() })

        store.handleLocationUpdate(referenceCoordinate, radiusKm: 5)
        try await Task.sleep(for: .milliseconds(20))

        let farNorth = CLLocation(latitude: 52.505, longitude: 13.4)
        store.forceRefresh(using: farNorth, radiusKm: 5)

        try await Task.sleep(for: .milliseconds(600))
        #expect(await fetcher.completedInvocationCount == 1)
    }
}
