import CoreLocation
import SwiftUI

@main
struct TankRadarApp: App {
    @State private var locationService = LocationService(snapshotStore: UserDefaultsLocationSnapshotStore())
    @State private var stationStore = StationStoreFactory.makeDefault()
    @AppStorage(AppSettings.UserDefaultsKey.appearancePreference) private var appearanceRaw = AppSettings.AppearancePreference.system.rawValue

    private var appearancePreference: AppSettings.AppearancePreference {
        AppSettings.AppearancePreference.resolved(storedRaw: appearanceRaw)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(appearancePreference.preferredSwiftUIColorScheme)
                .environment(locationService)
                .environment(stationStore)
                .environment(MapDeepLinkStore.shared)
                .onOpenURL { url in
                    Task { @MainActor in
                        guard let link = TankRadarDeepLink.parse(url) else { return }
                        switch link {
                        case .map:
                            MapDeepLinkStore.shared.clearPendingStationFocus()
                        case let .station(id):
                            MapDeepLinkStore.shared.enqueueStationFocus(id: id)
                        }
                    }
                }
                .task {
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
        CLLocationManager().requestWhenInUseAuthorization()
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
