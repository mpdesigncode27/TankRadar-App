import CoreLocation
import Foundation
import Testing
@testable import FuelNow

private final class StubNetworkPathProvider: NetworkPathProviding, @unchecked Sendable {
    private var continuation: AsyncStream<NetworkPathSnapshot>.Continuation?

    func makeStream() -> AsyncStream<NetworkPathSnapshot> {
        AsyncStream { continuation in
            self.continuation = continuation
        }
    }

    func cancel() {
        continuation?.finish()
        continuation = nil
    }

    func emit(_ snapshot: NetworkPathSnapshot) {
        continuation?.yield(snapshot)
    }

    func finish() {
        continuation?.finish()
        continuation = nil
    }
}

@Suite(.serialized)
@MainActor
struct NetworkMonitorTests {
    @Test func defaultsToOnlineWithSatisfiedSnapshot() {
        let monitor = NetworkMonitor(provider: StubNetworkPathProvider(), initialSnapshot: .satisfied)
        #expect(monitor.snapshot.isOnline)
        #expect(!monitor.shouldShowOfflineSplash)
    }

    @Test func ingestUnsatisfiedShowsSplash() {
        let monitor = NetworkMonitor(provider: StubNetworkPathProvider(), initialSnapshot: .satisfied)
        monitor.ingestForTesting(.unsatisfied)
        #expect(monitor.shouldShowOfflineSplash)
    }

    @Test func ingestSatisfiedClearsSplashFlag() {
        let monitor = NetworkMonitor(provider: StubNetworkPathProvider(), initialSnapshot: .unsatisfied)
        #expect(monitor.shouldShowOfflineSplash)
        monitor.ingestForTesting(.satisfied)
        #expect(!monitor.shouldShowOfflineSplash)
    }

    @Test func recordConnectivityFailureKeepsSplashEvenWhenOnline() {
        let monitor = NetworkMonitor(provider: StubNetworkPathProvider(), initialSnapshot: .satisfied)
        monitor.recordFetchOutcome(.connectivityFailure)
        #expect(monitor.shouldShowOfflineSplash)
        // Erfolgreicher Fetch hebt den Offline-Verdacht wieder auf:
        monitor.recordFetchOutcome(.success)
        #expect(!monitor.shouldShowOfflineSplash)
    }

    @Test func nonConnectivityFailureDoesNotShowSplash() {
        let monitor = NetworkMonitor(provider: StubNetworkPathProvider(), initialSnapshot: .satisfied)
        monitor.recordFetchOutcome(.otherFailure)
        #expect(!monitor.shouldShowOfflineSplash)
    }

    @Test func goingBackOnlineClearsFetchSuggestsOffline() {
        let monitor = NetworkMonitor(provider: StubNetworkPathProvider(), initialSnapshot: .unsatisfied)
        monitor.recordFetchOutcome(.connectivityFailure)
        #expect(monitor.shouldShowOfflineSplash)
        monitor.ingestForTesting(.satisfied)
        #expect(!monitor.shouldShowOfflineSplash)
    }

    @Test func startConsumesProviderUpdates() async throws {
        let provider = StubNetworkPathProvider()
        let monitor = NetworkMonitor(provider: provider, initialSnapshot: .satisfied)
        monitor.start()

        provider.emit(.unsatisfied)
        try await Task.sleep(for: .milliseconds(80))
        #expect(monitor.shouldShowOfflineSplash)

        provider.emit(.satisfied)
        try await Task.sleep(for: .milliseconds(80))
        #expect(!monitor.shouldShowOfflineSplash)

        monitor.stop()
    }

    @Test func classifyMapsURLErrorsToConnectivity() {
        #expect(NetworkMonitor.FetchOutcome.classify(URLError(.notConnectedToInternet)) == .connectivityFailure)
        #expect(NetworkMonitor.FetchOutcome.classify(URLError(.timedOut)) == .connectivityFailure)
        #expect(NetworkMonitor.FetchOutcome.classify(URLError(.networkConnectionLost)) == .connectivityFailure)
        #expect(NetworkMonitor.FetchOutcome.classify(URLError(.cannotFindHost)) == .connectivityFailure)
    }

    @Test func classifyMapsOtherURLErrorsToOther() {
        #expect(NetworkMonitor.FetchOutcome.classify(URLError(.cancelled)) == .otherFailure)
        #expect(NetworkMonitor.FetchOutcome.classify(URLError(.badServerResponse)) == .otherFailure)
    }

    @Test func classifyUnwrapsTankerkoenigNetworkFailure() {
        let wrapped = TankerkoenigClient.Failure.network(URLError(.notConnectedToInternet))
        #expect(NetworkMonitor.FetchOutcome.classify(wrapped) == .connectivityFailure)
    }

    @Test func classifyTankerkoenigNonNetworkFailureIsOther() {
        #expect(NetworkMonitor.FetchOutcome.classify(TankerkoenigClient.Failure.missingAPIKey) == .otherFailure)
        #expect(NetworkMonitor.FetchOutcome.classify(TankerkoenigClient.Failure.rateLimited) == .otherFailure)
        #expect(NetworkMonitor.FetchOutcome.classify(TankerkoenigClient.Failure.http(statusCode: 500)) == .otherFailure)
    }
}

@Suite(.serialized)
@MainActor
struct StationStoreFactoryTests {
    /// **TAN-91:** `FUELNOW_USE_MOCK_STATIONS=1` muss den Bundled-Fetcher liefern.
    @Test func mockOverrideUsesBundledFetcher() async throws {
        let store = StationStoreFactory.makeDefault(environment: ["FUELNOW_USE_MOCK_STATIONS": "1"])
        let location = CLLocation(latitude: 52.52, longitude: 13.405)
        store.forceRefresh(using: location, radiusKm: 25)
        try await Task.sleep(for: .milliseconds(120))

        switch store.loadState {
        case .loaded:
            #expect(!store.stations.isEmpty, "Bundled-Mock muss mindestens eine Station liefern.")
        default:
            Issue.record("Erwartet .loaded mit Bundled-Mock-Stationen, war: \(store.loadState)")
        }
    }

    /// Default-Pfad (kein Env-Override) erzeugt einen Live-Store. Wir lösen hier bewusst
    /// **keinen** Fetch aus — nur die Konstruktion soll geprüft werden, damit der Test
    /// keine Tankerkönig-Anfrage abschickt.
    @Test func defaultPathReturnsLiveStore() {
        let store = StationStoreFactory.makeDefault(environment: [:])
        #expect(store.stations.isEmpty)
        #expect(store.lastError == nil)
    }
}
