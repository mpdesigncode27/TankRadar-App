import SwiftUI

@main
struct FuelNowApp: App {
    @State private var locationService = LocationService(snapshotStore: UserDefaultsLocationSnapshotStore())
    @State private var stationStore = StationStoreFactory.makeDefault()
    @State private var entitlementManager = EntitlementManager()
    @State private var networkMonitor = NetworkMonitor()
    @AppStorage(AppSettings.UserDefaultsKey.appearancePreference)
    private var appearanceRaw = AppSettings.AppearancePreference.system.rawValue

    private var appearancePreference: AppSettings.AppearancePreference {
        AppSettings.AppearancePreference.resolved(storedRaw: appearanceRaw)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(appearancePreference.preferredSwiftUIColorScheme)
                .environment(locationService)
                .environment(stationStore)
                .environment(entitlementManager)
                .environment(networkMonitor)
                .environment(MapDeepLinkStore.shared)
                .onAppear {
                    FuelNowRuntimeRegistry.stationStore = stationStore
                    FuelNowRuntimeRegistry.locationService = locationService
                    networkMonitor.start()
                }
                .onOpenURL { url in
                    Task { @MainActor in
                        guard let link = FuelNowDeepLink.parse(url) else { return }
                        switch link {
                        case .map:
                            MapDeepLinkStore.shared.clearPendingStationFocus()
                        case let .station(id):
                            MapDeepLinkStore.shared.enqueueStationFocus(id: id)
                        }
                    }
                }
                .task {
                    await entitlementManager.start()
                    await requestLocationAuthorizationIfNeeded()
                    #if DEBUG
                    APIKeys.warnIfPlaceholderActive()
                    #endif
                }
        }
    }

    @MainActor
    private func requestLocationAuthorizationIfNeeded() async {
        guard ProcessInfo.processInfo.environment["UITESTING"] != "1" else { return }
        // Über den gehaltenen LocationService, nicht über eine Wegwerf-CLLocationManager-Instanz
        // (TAN-79): Apple verlangt eine über die Anfrage hinaus gehaltene Instanz mit Delegate,
        // sonst geht der System-Dialog/die Antwort verloren.
        locationService.requestWhenInUseAuthorizationIfNeeded()
    }
}

private extension AppSettings.AppearancePreference {
    var preferredSwiftUIColorScheme: ColorScheme? {
        switch self {
        case .system:
            nil
        case .light:
            .light
        case .dark:
            .dark
        }
    }
}
