import CoreLocation
import SwiftUI

@main
struct TankRadarApp: App {
    @State private var locationService = LocationService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(locationService)
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
