import Foundation

extension AppSettings {
    /// Kraftstoffsorte aus `UserDefaults` — gleicher Key wie ``SettingsView`` (`@AppStorage`).
    nonisolated static func preferredFuelFromStorage() -> FuelType {
        let raw = UserDefaults.standard.string(forKey: UserDefaultsKey.preferredFuelType) ?? FuelType.e10.rawValue
        return FuelType(rawValue: raw) ?? .e10
    }
}
