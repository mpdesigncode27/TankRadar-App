import CoreLocation
import Foundation
import MapKit
import SwiftUI

/// Einzelpin oder Cluster — SwiftUI-`Map` hat kein natives MKClustering; wir gruppieren nach sichtbarem Ausschnitt und Zoom.
enum MapStationAnnotationItem: Identifiable {
    case single(Station)
    case cluster(stations: [Station], coordinate: CLLocationCoordinate2D)

    var id: String {
        switch self {
        case .single(let station):
            station.id.uuidString
        case .cluster(let stations, _):
            Self.clusterIdentityKey(stations)
        }
    }

    var coordinate: CLLocationCoordinate2D {
        switch self {
        case .single(let station):
            station.coordinate
        case .cluster(_, let coordinate):
            coordinate
        }
    }

    static func clusterIdentityKey(_ stations: [Station]) -> String {
        stations.map(\.id.uuidString).sorted().joined(separator: "|")
    }
}

enum StationMapClustering {
    /// Gitter über die aktuelle Region — bei großem Zoom (große Span) weniger Zellen ⇒ stärkeres Clustern.
    static func annotationItems(for stations: [Station], region: MKCoordinateRegion) -> [MapStationAnnotationItem] {
        let visible = stationsVisible(in: region, stations: stations)
        guard !visible.isEmpty else { return [] }

        let divisions = gridDivisions(for: region)
        let latMin = region.center.latitude - region.span.latitudeDelta / 2
        let lonMin = region.center.longitude - region.span.longitudeDelta / 2
        let cellLat = max(region.span.latitudeDelta / Double(divisions), 1e-9)
        let cellLon = max(region.span.longitudeDelta / Double(divisions), 1e-9)

        var buckets: [[Station]] = []
        buckets.reserveCapacity(visible.count)

        var bucketIndexByKey: [String: Int] = [:]
        bucketIndexByKey.reserveCapacity(visible.count)

        for station in visible {
            let gi = min(divisions - 1, max(0, Int(floor((station.latitude - latMin) / cellLat))))
            let gj = min(divisions - 1, max(0, Int(floor((station.longitude - lonMin) / cellLon))))
            let key = "\(gi)_\(gj)"
            if let existing = bucketIndexByKey[key] {
                buckets[existing].append(station)
            } else {
                bucketIndexByKey[key] = buckets.count
                buckets.append([station])
            }
        }

        var items: [MapStationAnnotationItem] = []
        items.reserveCapacity(buckets.count)
        for bucket in buckets {
            if bucket.count == 1, let only = bucket.first {
                items.append(.single(only))
            } else {
                let coord = centroid(of: bucket)
                items.append(.cluster(stations: bucket, coordinate: coord))
            }
        }
        return items
    }

    /// Bounding box für Zoom nach Cluster-Tap — etwas Luft, damit Pins sich auflösen.
    static func regionToExpandCluster(_ stations: [Station], currentRegion: MKCoordinateRegion) -> MKCoordinateRegion {
        guard let minLat = stations.map(\.latitude).min(),
              let maxLat = stations.map(\.latitude).max(),
              let minLon = stations.map(\.longitude).min(),
              let maxLon = stations.map(\.longitude).max()
        else {
            return currentRegion
        }

        let center = centroid(of: stations)
        var latDelta = (maxLat - minLat) * 1.45
        var lonDelta = (maxLon - minLon) * 1.45
        latDelta = max(latDelta, 0.004)
        lonDelta = max(lonDelta, 0.004)
        latDelta = min(latDelta, max(currentRegion.span.latitudeDelta * 0.9, 0.004))
        lonDelta = min(lonDelta, max(currentRegion.span.longitudeDelta * 0.9, 0.004))

        return MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta))
    }

    private static func stationsVisible(in region: MKCoordinateRegion, stations: [Station]) -> [Station] {
        let padLat = region.span.latitudeDelta * 0.12
        let padLon = region.span.longitudeDelta * 0.12
        let minLat = region.center.latitude - region.span.latitudeDelta / 2 - padLat
        let maxLat = region.center.latitude + region.span.latitudeDelta / 2 + padLat
        let minLon = region.center.longitude - region.span.longitudeDelta / 2 - padLon
        let maxLon = region.center.longitude + region.span.longitudeDelta / 2 + padLon

        return stations.filter { s in
            s.latitude >= minLat && s.latitude <= maxLat && s.longitude >= minLon && s.longitude <= maxLon
        }
    }

    private static func gridDivisions(for region: MKCoordinateRegion) -> Int {
        let extent = max(region.span.latitudeDelta, region.span.longitudeDelta)
        switch extent {
        case ..<0.014:
            return 26
        case ..<0.024:
            return 22
        case ..<0.038:
            return 18
        case ..<0.065:
            return 14
        case ..<0.11:
            return 10
        default:
            return 7
        }
    }

    private static func centroid(of stations: [Station]) -> CLLocationCoordinate2D {
        let lat = stations.map(\.latitude).reduce(0, +) / Double(stations.count)
        let lon = stations.map(\.longitude).reduce(0, +) / Double(stations.count)
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}

/// Cluster-Pille (Anzahl) — gleiches Glasmaterial wie Einzel-Pins.
struct StationClusterAnnotationView: View {
    let count: Int

    var body: some View {
        Text("\(count)")
            .font(TRTypography.bodyBold())
            .foregroundStyle(TRColors.labelPrimary)
            .frame(minWidth: 44, minHeight: 44)
            .padding(.horizontal, TRSpacing.s)
            .trGlassPill(interactive: true)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(count) Tankstellen")
            .accessibilityHint("Tippen, um näher heranzuzoomen und die Stationen einzeln zu sehen.")
    }
}
