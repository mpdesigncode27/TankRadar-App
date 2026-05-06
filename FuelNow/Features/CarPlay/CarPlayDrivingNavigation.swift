#if canImport(CarPlay)
import CoreLocation
import MapKit

/// Startet die Apple-Maps-**Autoroute** zur Tankstelle — gleiches Verhalten wie ``StationDetailView``.
enum CarPlayDrivingNavigation {
    @MainActor
    static func openDrivingDirections(to station: Station) {
        let destinationLocation = CLLocation(latitude: station.latitude, longitude: station.longitude)
        let destination = MKMapItem(location: destinationLocation, address: nil)
        destination.name = station.name

        let current = MKMapItem.forCurrentLocation()
        MKMapItem.openMaps(
            with: [current, destination],
            launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
        )
    }
}
#endif
