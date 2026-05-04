import Foundation

/// Merkt sich eine per Deep Link oder Open-Intent angeforderte Tankstelle und synchronisiert nach `UserDefaults` (Cold Start / Intents).
///
/// Mutations aus Intents laufen über `MainActor.run` in der App; `UserDefaults` ist threadsicher.
@Observable
final class MapDeepLinkStore {
    /// Globale Instanz für App Intents und `TankRadarApp` (Zugriffe über `MainActor.run` / UI).
    nonisolated(unsafe) static let shared = MapDeepLinkStore()

    private let defaults: UserDefaults

    private(set) var pendingStationFocusID: UUID?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let str = defaults.string(forKey: AppSettings.UserDefaultsKey.pendingMapStationFocusID),
           let id = UUID(uuidString: str) {
            pendingStationFocusID = id
        }
    }

    func enqueueStationFocus(id: UUID) {
        pendingStationFocusID = id
        defaults.set(id.uuidString, forKey: AppSettings.UserDefaultsKey.pendingMapStationFocusID)
    }

    func clearPendingStationFocus() {
        pendingStationFocusID = nil
        defaults.removeObject(forKey: AppSettings.UserDefaultsKey.pendingMapStationFocusID)
    }
}
