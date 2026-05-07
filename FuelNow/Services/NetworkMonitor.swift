import Foundation
import Network
import Observation

/// Sendable-Snapshot des aktuellen Netzwerkstatus — entkoppelt `Network.NWPath` vom UI-Layer
/// und lässt sich in Tests deterministisch erzeugen.
struct NetworkPathSnapshot: Sendable, Equatable {
    enum Reachability: Sendable, Equatable {
        case satisfied
        case unsatisfied
    }

    let reachability: Reachability
    let isExpensive: Bool
    let isConstrained: Bool

    var isOnline: Bool {
        reachability == .satisfied
    }

    static let unsatisfied = NetworkPathSnapshot(
        reachability: .unsatisfied,
        isExpensive: false,
        isConstrained: false
    )

    static let satisfied = NetworkPathSnapshot(
        reachability: .satisfied,
        isExpensive: false,
        isConstrained: false
    )
}

/// Abstraktion über `NWPathMonitor`, damit `NetworkMonitor` in Unit-Tests ohne echten
/// System-Pathmonitor deterministisch befüllt werden kann.
protocol NetworkPathProviding: AnyObject, Sendable {
    /// Asynchroner Stream mit Pfad-Updates. Sollte bei Termination beendet werden.
    func makeStream() -> AsyncStream<NetworkPathSnapshot>
    /// Beendet eventuell aktive Path-Beobachtung (idempotent).
    func cancel()
}

/// Produktive Quelle auf Basis von `NWPathMonitor`.
final class LiveNetworkPathProvider: NetworkPathProviding, @unchecked Sendable {
    private let monitor: NWPathMonitor
    private let queue: DispatchQueue
    private var continuation: AsyncStream<NetworkPathSnapshot>.Continuation?

    init(monitor: NWPathMonitor = NWPathMonitor(), queue: DispatchQueue = DispatchQueue(label: "com.fuelnow.network-monitor", qos: .utility)) {
        self.monitor = monitor
        self.queue = queue
    }

    deinit {
        cancel()
    }

    func makeStream() -> AsyncStream<NetworkPathSnapshot> {
        AsyncStream { continuation in
            self.continuation = continuation
            monitor.pathUpdateHandler = { path in
                continuation.yield(NetworkPathSnapshot(path: path))
            }
            continuation.onTermination = { @Sendable [weak self] _ in
                self?.cancel()
            }
            monitor.start(queue: queue)
        }
    }

    func cancel() {
        monitor.pathUpdateHandler = nil
        monitor.cancel()
        continuation?.finish()
        continuation = nil
    }
}

private extension NetworkPathSnapshot {
    init(path: NWPath) {
        self.init(
            reachability: path.status == .satisfied ? .satisfied : .unsatisfied,
            isExpensive: path.isExpensive,
            isConstrained: path.isConstrained
        )
    }
}

/// Beobachtet den System-Netzwerkstatus und exposed `isOnline` für SwiftUI.
///
/// **TAN-91:** Dient als Splash-Trigger, wenn entweder `NWPathMonitor` `unsatisfied` meldet
/// **oder** ein Tankerkönig-Fetch mit `URLError(.notConnectedToInternet)` /
/// `URLError(.timedOut)` fehlschlägt. Letzteres wird über `recordFetchOutcome(_:)` aus
/// `MapScreen` gesetzt.
@MainActor
@Observable
final class NetworkMonitor {
    private(set) var snapshot: NetworkPathSnapshot
    /// True, wenn der zuletzt versuchte Stations-Fetch wegen Konnektivität fehlschlug.
    private(set) var lastFetchSuggestsOffline: Bool = false

    @ObservationIgnored
    private let provider: any NetworkPathProviding
    @ObservationIgnored
    nonisolated(unsafe) private var streamTask: Task<Void, Never>?

    init(
        provider: any NetworkPathProviding = LiveNetworkPathProvider(),
        initialSnapshot: NetworkPathSnapshot = .satisfied
    ) {
        self.provider = provider
        self.snapshot = initialSnapshot
    }

    deinit {
        streamTask?.cancel()
        provider.cancel()
    }

    /// Startet die Pfadbeobachtung (idempotent — mehrmaliges Aufrufen ist no-op).
    func start() {
        guard streamTask == nil else { return }
        let stream = provider.makeStream()
        streamTask = Task { [weak self] in
            for await update in stream {
                guard let self else { return }
                await MainActor.run {
                    self.apply(snapshot: update)
                }
            }
        }
    }

    /// Stoppt die Pfadbeobachtung. `start()` kann danach erneut aufgerufen werden.
    func stop() {
        streamTask?.cancel()
        streamTask = nil
        provider.cancel()
    }

    /// Sollte das UI den Offline-Splash anzeigen?
    var shouldShowOfflineSplash: Bool {
        !snapshot.isOnline || lastFetchSuggestsOffline
    }

    /// Ergebnis eines Tankerkönig-Fetches einarbeiten — markiert „offline by fetch failure“,
    /// solange `NWPathMonitor` selbst ggf. noch nicht reagiert hat (z. B. flaky WLAN).
    func recordFetchOutcome(_ outcome: FetchOutcome) {
        switch outcome {
        case .success:
            lastFetchSuggestsOffline = false
        case .connectivityFailure:
            lastFetchSuggestsOffline = true
        case .otherFailure:
            // Nicht-Konnektivitäts-Fehler (HTTP 429, fehlender Key, ok=false) bleiben im
            // bestehenden Error-Alert sichtbar — der Splash bleibt aus.
            lastFetchSuggestsOffline = false
        }
    }

    /// **Test-Hook:** spielt einen Snapshot direkt ein, ohne `start()` zu durchlaufen.
    func ingestForTesting(_ snapshot: NetworkPathSnapshot) {
        apply(snapshot: snapshot)
    }

    enum FetchOutcome: Sendable, Equatable {
        case success
        case connectivityFailure
        case otherFailure
    }

    private func apply(snapshot: NetworkPathSnapshot) {
        self.snapshot = snapshot
        if snapshot.isOnline {
            lastFetchSuggestsOffline = false
        }
    }
}

extension NetworkMonitor.FetchOutcome {
    /// Klassifiziert einen `Error` aus `StationFetching` in eine `FetchOutcome`.
    static func classify(_ error: Error) -> NetworkMonitor.FetchOutcome {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet,
                 .timedOut,
                 .networkConnectionLost,
                 .dataNotAllowed,
                 .internationalRoamingOff,
                 .cannotFindHost,
                 .cannotConnectToHost,
                 .dnsLookupFailed:
                return .connectivityFailure
            default:
                return .otherFailure
            }
        }
        if let tankerkoenig = error as? TankerkoenigClient.Failure {
            switch tankerkoenig {
            case let .network(urlError):
                return classify(urlError)
            default:
                return .otherFailure
            }
        }
        return .otherFailure
    }
}
