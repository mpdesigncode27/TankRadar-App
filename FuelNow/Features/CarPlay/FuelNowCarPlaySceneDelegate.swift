#if canImport(CarPlay)
import CarPlay
import Foundation
import MapKit
import Observation
import UIKit

/// CarPlay Scene Delegate — Plus-Gating (TAN-56), POI-Erfahrung (TAN-55), Limited UI (TAN-57).
final class FuelNowCarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    static var entitlementProviderFactory: @MainActor () -> any CarPlayEntitlementProviding = {
        EntitlementManager()
    }

    private var interfaceController: CPInterfaceController?
    private var entitlementProvider: (any CarPlayEntitlementProviding)?
    /// Letzte Routing-Pfadentscheidung (Plus vs. Limited — nur bei Wechsel wird Limited neu gesetzt).
    private var lastRoutingPath: CarPlayRoute?
    /// Verhindert unnötige `setRootTemplate`-Aufrufe im Plus-Pfad bei gleicher Datenlage.
    private var lastPlusUISnapshot: PlusUISnapshot?
    private var didStartEntitlementObservation = false
    private var didStartStationObservation = false

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        self.interfaceController = interfaceController
        let provider = Self.entitlementProviderFactory()
        entitlementProvider = provider
        Task { @MainActor in
            await provider.start()
            primeStationFetchForCarPlay()
            lastRoutingPath = nil
            lastPlusUISnapshot = nil
            reconcileCarPlayUI(animated: false)
            armEntitlementObservation()
            armStationObservationIfPossible()
        }
    }

    // MARK: - Observation

    @MainActor
    private func armEntitlementObservation() {
        didStartEntitlementObservation = true
        guard let provider = entitlementProvider else { return }
        withObservationTracking {
            _ = provider.isCarPlayUnlocked
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                guard let self, self.didStartEntitlementObservation else { return }
                self.reconcileCarPlayUI(animated: true)
                self.armEntitlementObservation()
            }
        }
    }

    @MainActor
    private func armStationObservationIfPossible() {
        guard FuelNowRuntimeRegistry.stationStore != nil else { return }
        guard let store = FuelNowRuntimeRegistry.stationStore else { return }
        didStartStationObservation = true
        withObservationTracking {
            _ = store.stations
            _ = store.loadState
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                guard let self, self.didStartStationObservation else { return }
                self.reconcileCarPlayUI(animated: true)
                self.armStationObservationIfPossible()
            }
        }
    }

    // MARK: - Routing & Templates

    @MainActor
    private func reconcileCarPlayUI(animated: Bool) {
        guard let interfaceController else { return }
        let unlocked = entitlementProvider?.isCarPlayUnlocked ?? false
        let route = CarPlayRoutingPolicy.route(forCarPlayUnlocked: unlocked)

        if route == .limited {
            lastPlusUISnapshot = nil
            if lastRoutingPath != .limited {
                lastRoutingPath = .limited
                interfaceController.setRootTemplate(makeLimitedTemplate(), animated: animated, completion: nil)
            }
            return
        }

        if lastRoutingPath != .plus {
            lastRoutingPath = .plus
            lastPlusUISnapshot = nil
        }
        updatePlusRootIfNeeded(interfaceController: interfaceController, animated: animated)
    }

    @MainActor
    private func updatePlusRootIfNeeded(interfaceController: CPInterfaceController, animated: Bool) {
        let store = FuelNowRuntimeRegistry.stationStore ?? StationStoreFactory.makeDefault()
        let snapshot = PlusUISnapshot(store: store)
        guard snapshot != lastPlusUISnapshot else { return }
        lastPlusUISnapshot = snapshot
        interfaceController.setRootTemplate(
            makePlusRootTemplate(store: store, snapshot: snapshot),
            animated: animated,
            completion: nil
        )
    }

    @MainActor
    private func makeLimitedTemplate() -> CPInformationTemplate {
        CPInformationTemplate(
            title: String(localized: "carplay.locked.title"),
            layout: .leading,
            items: [
                CPInformationItem(
                    title: String(localized: "carplay.locked.body"),
                    detail: nil
                ),
                CPInformationItem(
                    title: String(localized: "carplay.locked.detail"),
                    detail: nil
                ),
            ],
            actions: []
        )
    }

    @MainActor
    private func makePlusRootTemplate(store: StationStore, snapshot: PlusUISnapshot) -> CPTemplate {
        switch snapshot.kind {
        case .loadingWithoutStations:
            return CPInformationTemplate(
                title: String(localized: "carplay.plus.loading.title"),
                layout: .leading,
                items: [
                    CPInformationItem(
                        title: String(localized: "carplay.plus.loading.body"),
                        detail: nil
                    ),
                ],
                actions: []
            )
        case .idleWithoutStations:
            return CPInformationTemplate(
                title: String(localized: "carplay.plus.idle.title"),
                layout: .leading,
                items: [
                    CPInformationItem(
                        title: String(localized: "carplay.plus.idle.body"),
                        detail: nil
                    ),
                ],
                actions: []
            )
        case .loadedEmpty:
            return CPInformationTemplate(
                title: String(localized: "carplay.plus.empty.title"),
                layout: .leading,
                items: [
                    CPInformationItem(
                        title: String(localized: "carplay.plus.empty.body"),
                        detail: nil
                    ),
                ],
                actions: []
            )
        case let .failed(message):
            return CPInformationTemplate(
                title: String(localized: "carplay.plus.error.title"),
                layout: .leading,
                items: [
                    CPInformationItem(
                        title: message,
                        detail: nil
                    ),
                ],
                actions: []
            )
        case .stations:
            let fuel = AppSettings.preferredFuelFromStorage()
            let stations = store.stations
            let rows = StationCarPlayPOIMapper.buildRows(stations: stations, preferredFuel: fuel)
            let byID = Dictionary(uniqueKeysWithValues: stations.map { ($0.id, $0) })
            let points = StationCarPlayPOIMapper.makePointsOfInterest(rows: rows, stationsByID: byID)
            let poiTemplate = StationCarPlayPOIMapper.makePointsTemplate(points: points, delegate: self)
            let listTemplate = StationCarPlayPOIMapper.makeNearbyListTemplate(stations: stations, preferredFuel: fuel)
            return CPTabBarTemplate(templates: [poiTemplate, listTemplate])
        }
    }

    @MainActor
    private func primeStationFetchForCarPlay() {
        guard let store = FuelNowRuntimeRegistry.stationStore else { return }
        guard let location = FuelNowRuntimeRegistry.locationService?.currentLocation else { return }
        store.handleLocationUpdate(location, radiusKm: AppSettings.SearchRadius.apiMaxKm, force: false)
    }
}

// MARK: - Plus UI Snapshot

private struct PlusUISnapshot: Equatable {
    enum Kind: Equatable {
        case loadingWithoutStations
        case idleWithoutStations
        case loadedEmpty
        case failed(String)
        case stations([UUID])
    }

    let kind: Kind

    @MainActor
    init(store: StationStore) {
        switch store.loadState {
        case let .failed(message):
            if store.stations.isEmpty {
                kind = .failed(message)
            } else {
                kind = .stations(store.stations.map(\.id))
            }
        case .loading where store.stations.isEmpty:
            kind = .loadingWithoutStations
        case .loading:
            kind = .stations(store.stations.map(\.id))
        case .idle where store.stations.isEmpty:
            kind = .idleWithoutStations
        case .idle:
            kind = .stations(store.stations.map(\.id))
        case .loaded where store.stations.isEmpty:
            kind = .loadedEmpty
        case .loaded:
            kind = .stations(store.stations.map(\.id))
        }
    }
}

// MARK: - POI delegate (Map-Region — MVP ohne Nachladen)

extension FuelNowCarPlaySceneDelegate: CPPointOfInterestTemplateDelegate {
    func pointOfInterestTemplate(
        _: CPPointOfInterestTemplate,
        didChangeMapRegion _: MKCoordinateRegion
    ) {
        // MVP: keine zusätzliche Tankerkönig-Anfrage bei Pan/Zoom — gleiches Datenmodell wie die Karten-
        // Hauptansicht (StationStore lokal). Region-basiertes Nachladen wäre ein Folge-Ticket (Caching/TAN-83).
    }
}

// MARK: - Disconnect

extension FuelNowCarPlaySceneDelegate {
    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnect interfaceController: CPInterfaceController
    ) {
        self.interfaceController = nil
        entitlementProvider = nil
        lastRoutingPath = nil
        lastPlusUISnapshot = nil
        didStartEntitlementObservation = false
        didStartStationObservation = false
    }
}
#endif
