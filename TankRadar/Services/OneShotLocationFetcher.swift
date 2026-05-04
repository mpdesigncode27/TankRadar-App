import CoreLocation
import Foundation

/// Einmalige Standortabfrage für Cache-Miss (Hauptthread / `CLLocationManager`).
protocol OneShotLocationFetching: Sendable {
    func fetchSnapshot() async throws -> LocationSnapshot
}

/// Produktion: ein `CLLocationManager.requestLocation()`-Zyklus auf dem Main Actor.
struct MainActorOneShotLocationFetcher: OneShotLocationFetching {
    func fetchSnapshot() async throws -> LocationSnapshot {
        try await MainActorOneShotLocationOperation().perform()
    }
}

@MainActor
private final class MainActorOneShotLocationOperation: NSObject, @preconcurrency CLLocationManagerDelegate {
    private var manager: CLLocationManager?
    private var continuation: CheckedContinuation<LocationSnapshot, Error>?

    func perform() async throws -> LocationSnapshot {
        try await withCheckedThrowingContinuation { cont in
            continuation = cont
            let m = CLLocationManager()
            manager = m
            m.delegate = self

            switch m.authorizationStatus {
            case .authorizedAlways, .authorizedWhenInUse:
                m.requestLocation()
            case .denied, .restricted:
                resumeFailure(LocationProviderError.notAuthorized)
            case .notDetermined:
                m.requestWhenInUseAuthorization()
            @unknown default:
                resumeFailure(LocationProviderError.notAuthorized)
            }
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard continuation != nil else { return }
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        case .denied, .restricted:
            resumeFailure(LocationProviderError.notAuthorized)
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            resumeFailure(LocationProviderError.locationUnavailable)
            return
        }
        guard location.horizontalAccuracy >= 0 else {
            resumeFailure(LocationProviderError.locationUnavailable)
            return
        }
        continuation?.resume(returning: LocationSnapshot(location: location))
        cleanup()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        continuation?.resume(throwing: error)
        cleanup()
    }

    private func resumeFailure(_ error: Error) {
        continuation?.resume(throwing: error)
        cleanup()
    }

    private func cleanup() {
        continuation = nil
        manager?.delegate = nil
        manager = nil
    }
}
