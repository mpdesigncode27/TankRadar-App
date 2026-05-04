import CoreLocation
import MapKit
import SwiftUI

/// Hauptkarte: Standort, Tankstellen-Pins und Verkabelung zu `LocationService` / `StationStore`.
struct MapScreen: View {
    @Environment(LocationService.self) private var locationService
    @Environment(StationStore.self) private var stationStore

    @AppStorage("tr.searchRadiusKm") private var searchRadiusKm = 5
    @AppStorage("tr.preferredFuelType") private var preferredFuelRaw = FuelType.e10.rawValue

    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 52.52, longitude: 13.405),
            span: MKCoordinateSpan(latitudeDelta: 0.12, longitudeDelta: 0.12)
        )
    )
    @State private var selectedStation: Station?
    @State private var showSettings = false
    @State private var didApplyInitialCamera = false

    private var preferredFuel: FuelType {
        FuelType(rawValue: preferredFuelRaw) ?? .e10
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Map(position: $cameraPosition) {
                UserAnnotation()
                ForEach(stationStore.stations) { station in
                    Annotation(station.name, coordinate: station.coordinate) {
                        StationMapPinView()
                            .onTapGesture {
                                selectedStation = station
                            }
                    }
                }
            }
            .mapStyle(.standard)
            .refreshable {
                await refreshStations()
            }

            locateFloatingButton
                .padding(TRSpacing.m)
        }
        .navigationTitle("TankRadar")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Einstellungen", systemImage: "gearshape.fill") {
                    showSettings = true
                }
                .accessibilityLabel("Einstellungen")
            }
        }
        .sheet(item: $selectedStation) { station in
            StationDetailPlaceholderView(station: station, preferredFuel: preferredFuel)
        }
        .sheet(isPresented: $showSettings) {
            SettingsPlaceholderView()
        }
        .overlay(alignment: .top) {
            loadStateBanner
        }
        .task {
            locationService.start()
        }
        .onChange(of: locationService.currentLocation) { _, newValue in
            guard let location = newValue else { return }
            stationStore.handleLocationUpdate(location, radiusKm: Double(searchRadiusKm))
            if !didApplyInitialCamera {
                didApplyInitialCamera = true
                cameraPosition = .region(
                    MKCoordinateRegion(
                        center: location.coordinate,
                        latitudinalMeters: 12_000,
                        longitudinalMeters: 12_000
                    )
                )
            }
        }
    }

    @ViewBuilder
    private var loadStateBanner: some View {
        switch stationStore.loadState {
        case .loading:
            ProgressView()
                .padding(TRSpacing.s)
                .background(.ultraThinMaterial, in: Capsule())
                .padding(.top, TRSpacing.s)
        case let .failed(message):
            Text(message)
                .font(TRTypography.caption())
                .foregroundStyle(TRColors.labelPrimary)
                .padding(TRSpacing.s)
                .frame(maxWidth: .infinity)
                .background(TRColors.accent.opacity(0.15))
        default:
            EmptyView()
        }
    }

    private var locateFloatingButton: some View {
        Button {
            centerMapOnUser()
        } label: {
            Image(systemName: "location.fill")
                .font(.system(size: TRSpacing.m, weight: .semibold))
                .foregroundStyle(TRColors.labelPrimary)
                .frame(width: TRSpacing.xl, height: TRSpacing.xl)
                .background(.ultraThinMaterial, in: Circle())
                .shadow(color: .black.opacity(0.12), radius: TRSpacing.xxs, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Karte auf Standort zentrieren")
    }

    private func centerMapOnUser() {
        guard let location = locationService.currentLocation else { return }
        cameraPosition = .region(
            MKCoordinateRegion(
                center: location.coordinate,
                latitudinalMeters: 8_000,
                longitudinalMeters: 8_000
            )
        )
    }

    private func refreshStations() async {
        guard let location = locationService.currentLocation else { return }
        stationStore.forceRefresh(using: location, radiusKm: Double(searchRadiusKm))
        try? await Task.sleep(for: .milliseconds(400))
    }
}

/// Einfacher Pin bis **TAN-17** (Glass / Preis-Annotation).
private struct StationMapPinView: View {
    var body: some View {
        Circle()
            .fill(TRColors.accent.opacity(0.92))
            .frame(width: TRSpacing.s, height: TRSpacing.s)
            .overlay {
                Circle()
                    .stroke(TRColors.background, lineWidth: 2)
            }
            .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
    }
}

// MARK: - Previews

private struct StationListEnvelope: Decodable {
    let stations: [Station]
}

private actor PreviewStationFetcher: StationFetching {
    private let stations: [Station]

    init(stations: [Station]) {
        self.stations = stations
    }

    func fetchStations(latitude: Double, longitude: Double, radiusKm: Double) async throws -> [Station] {
        stations
    }
}

private struct PreviewLocationStreamProvider: LocationStreamProviding {
    func makeStream() -> AsyncThrowingStream<LocationStreamEvent, Error> {
        AsyncThrowingStream { continuation in
            continuation.yield(LocationStreamEvent(latitude: 52.53, longitude: 13.44, horizontalAccuracy: 10))
            continuation.finish()
        }
    }
}

private enum MapScreenPreviewData {
    static let stations: [Station] = {
        let json = Data(
            """
            {"stations":[{"id":"474e5046-deaf-4f9b-9a32-9797b778f047","name":"TOTAL BERLIN","brand":"TOTAL","street":"MARGARETE-SOMMER-STR.","place":"BERLIN","lat":52.53083,"lng":13.440946,"dist":1.1,"diesel":1.109,"e5":1.339,"e10":1.319,"isOpen":true,"houseNumber":"2","postCode":10407}]}
            """.utf8
        )
        return (try? JSONDecoder().decode(StationListEnvelope.self, from: json).stations) ?? []
    }()
}

#Preview("Light") {
    NavigationStack {
        MapScreen()
    }
    .environment(LocationService(streamProvider: PreviewLocationStreamProvider(), authorizationProvider: { .authorizedWhenInUse }))
    .environment(StationStore(fetcher: PreviewStationFetcher(stations: MapScreenPreviewData.stations)))
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        MapScreen()
    }
    .environment(LocationService(streamProvider: PreviewLocationStreamProvider(), authorizationProvider: { .authorizedWhenInUse }))
    .environment(StationStore(fetcher: PreviewStationFetcher(stations: MapScreenPreviewData.stations)))
    .preferredColorScheme(.dark)
}
