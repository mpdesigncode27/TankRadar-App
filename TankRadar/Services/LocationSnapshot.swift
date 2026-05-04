import CoreLocation
import Foundation

/// Snapshot eines gültigen Gerätestandorts für Cache und App Intents (`Sendable`).
struct LocationSnapshot: Sendable, Equatable {
    let latitude: Double
    let longitude: Double
    let horizontalAccuracy: Double
    /// Wann der Snapshot für die TTL gewertet wird (nicht zwingend `CLLocation.timestamp`).
    let recordedAt: Date

    init(latitude: Double, longitude: Double, horizontalAccuracy: Double, recordedAt: Date = Date()) {
        self.latitude = latitude
        self.longitude = longitude
        self.horizontalAccuracy = horizontalAccuracy
        self.recordedAt = recordedAt
    }

    init(location: CLLocation, recordedAt: Date = Date()) {
        latitude = location.coordinate.latitude
        longitude = location.coordinate.longitude
        horizontalAccuracy = location.horizontalAccuracy
        self.recordedAt = recordedAt
    }

    /// Nur für Anzeige / Routing; negative Genauigkeit gilt als ungültig.
    var clLocation: CLLocation {
        CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            altitude: 0,
            horizontalAccuracy: horizontalAccuracy,
            verticalAccuracy: -1,
            timestamp: recordedAt
        )
    }

    /// Ob der Snapshot aus Live-GPS stammen kann (gleiche Heuristik wie `LocationStreamEvent.makeLocation()`).
    var isAccuracyValid: Bool {
        horizontalAccuracy >= 0
    }
}

enum LocationProviderError: Error, Equatable {
    case notAuthorized
    case locationUnavailable
}

/// Liest/schreibt zwischengespeicherte Standorte (typisch `UserDefaults`).
protocol LocationSnapshotStore: Sendable {
    func loadValid(referenceDate: Date, ttl: TimeInterval) -> LocationSnapshot?
    func save(_ snapshot: LocationSnapshot)
}

/// Standard-Implementierung; `UserDefaults` ist threadsicher (Apple), typsystem-seitig `@unchecked Sendable`.
struct UserDefaultsLocationSnapshotStore: LocationSnapshotStore, @unchecked Sendable {
    let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadValid(referenceDate: Date, ttl: TimeInterval) -> LocationSnapshot? {
        guard
            defaults.object(forKey: AppSettings.UserDefaultsKey.locationCacheRecordedAt) != nil,
            defaults.object(forKey: AppSettings.UserDefaultsKey.locationCacheLatitude) != nil,
            defaults.object(forKey: AppSettings.UserDefaultsKey.locationCacheLongitude) != nil,
            defaults.object(forKey: AppSettings.UserDefaultsKey.locationCacheHorizontalAccuracy) != nil
        else {
            return nil
        }

        let recordedAt = Date(timeIntervalSince1970: defaults.double(forKey: AppSettings.UserDefaultsKey.locationCacheRecordedAt))
        guard referenceDate.timeIntervalSince(recordedAt) < ttl else { return nil }

        let lat = defaults.double(forKey: AppSettings.UserDefaultsKey.locationCacheLatitude)
        let lng = defaults.double(forKey: AppSettings.UserDefaultsKey.locationCacheLongitude)
        let accuracy = defaults.double(forKey: AppSettings.UserDefaultsKey.locationCacheHorizontalAccuracy)
        let snapshot = LocationSnapshot(latitude: lat, longitude: lng, horizontalAccuracy: accuracy, recordedAt: recordedAt)
        guard snapshot.isAccuracyValid else { return nil }
        return snapshot
    }

    func save(_ snapshot: LocationSnapshot) {
        guard snapshot.isAccuracyValid else { return }
        defaults.set(snapshot.latitude, forKey: AppSettings.UserDefaultsKey.locationCacheLatitude)
        defaults.set(snapshot.longitude, forKey: AppSettings.UserDefaultsKey.locationCacheLongitude)
        defaults.set(snapshot.horizontalAccuracy, forKey: AppSettings.UserDefaultsKey.locationCacheHorizontalAccuracy)
        defaults.set(snapshot.recordedAt.timeIntervalSince1970, forKey: AppSettings.UserDefaultsKey.locationCacheRecordedAt)
    }
}
