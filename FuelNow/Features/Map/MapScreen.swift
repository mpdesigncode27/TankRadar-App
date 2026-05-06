import CoreLocation
import MapKit
import SwiftUI
import UIKit

/// Hauptkarte: Standort, Tankstellen-Pins und Verkabelung zu `LocationService` / `StationStore`.
struct MapScreen: View {
    @Environment(LocationService.self) private var locationService
    @Environment(StationStore.self) private var stationStore
    @Environment(MapDeepLinkStore.self) private var deepLinks
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @AppStorage(AppSettings.UserDefaultsKey.preferredFuelType) private var preferredFuelRaw = FuelType.e10.rawValue

    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 52.52, longitude: 13.405),
            span: MKCoordinateSpan(latitudeDelta: 0.12, longitudeDelta: 0.12)
        )
    )
    @State private var selectedStation: Station?
    @State private var showSettings = false
    @State private var didApplyInitialCamera = false
    /// Gesetzt bei `.failed`, geleert bei anderem `loadState` — steuert den Retry-Alert (TAN-22).
    @State private var presentedFetchErrorMessage: String?

    private var preferredFuel: FuelType {
        FuelType(rawValue: preferredFuelRaw) ?? .e10
    }

    private var isLocationAccessDenied: Bool {
        switch locationService.authorizationStatus {
        case .denied, .restricted:
            true
        default:
            false
        }
    }

    /// Erfolgreicher Fetch ohne Treffer — nicht bei verweigerter Location oder vor erstem Standort.
    private var showEmptyStationsState: Bool {
        guard !isLocationAccessDenied else { return false }
        guard locationService.currentLocation != nil else { return false }
        guard case .loaded = stationStore.loadState else { return false }
        return stationStore.stations.isEmpty
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Map(position: $cameraPosition) {
                ForEach(stationStore.stations) { station in
                    Annotation(station.name, coordinate: station.coordinate) {
                        Button {
                            selectedStation = station
                        } label: {
                            StationAnnotationView(station: station, preferredFuel: preferredFuel)
                        }
                        .buttonStyle(.plain)
                    }
                }
                // Explizit aus LocationService — zuverlässiger als UserAnnotation() bei gebundenem MapCamera & vielen Pins.
                if let userLocation = locationService.currentLocation {
                    Annotation("", coordinate: userLocation.coordinate) {
                        UserLocationMapMarker()
                    }
                    .annotationTitles(.hidden)
                    .annotationSubtitles(.hidden)
                }
            }
            .mapStyle(.standard)
            .refreshable {
                await refreshStations()
            }

            LocateMeButton {
                centerMapOnUser()
            }
            .disabled(locationService.currentLocation == nil)
            .opacity(locationService.currentLocation == nil ? 0.45 : 1)
            .padding(TRSpacing.m)
        }
        .navigationTitle("FuelNow")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Einstellungen", systemImage: "gearshape.fill") {
                    showSettings = true
                }
                .accessibilityLabel("Einstellungen")
                .accessibilityHint("Öffnet Spritart, Erscheinungsbild und Datenquelle.")
            }
        }
        .sheet(item: $selectedStation) { station in
            StationDetailView(station: station, preferredFuel: preferredFuel)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .overlay(alignment: .top) {
            loadStateBanner
        }
        .overlay {
            if showEmptyStationsState {
                ContentUnavailableView {
                    Label("Keine Tankstellen im 25-km-Umkreis", systemImage: "fuelpump.slash")
                } description: {
                    Text("Versuche es an einem anderen Ort oder lade die Karte erneut.")
                } actions: {
                    Button("Erneut laden") {
                        retryStationFetch()
                    }
                    .buttonStyle(TRPrimaryGlassButtonStyle())
                }
                .padding(TRSpacing.m)
                .accessibilityLabel("Keine Tankstellen im 25-km-Umkreis")
            }
        }
        .overlay {
            if isLocationAccessDenied {
                LocationDeniedCallout {
                    showSettings = true
                }
                .transition(.opacity)
            }
        }
        .animation(reduceMotion ? nil : .default, value: isLocationAccessDenied)
        .animation(reduceMotion ? nil : .default, value: showEmptyStationsState)
        .alert(
            "Tankstellen konnten nicht geladen werden",
            isPresented: Binding(
                get: { presentedFetchErrorMessage != nil },
                set: { newValue in
                    if !newValue { presentedFetchErrorMessage = nil }
                }
            )
        ) {
            Button("Erneut versuchen") {
                presentedFetchErrorMessage = nil
                retryStationFetch()
            }
            Button("OK", role: .cancel) {
                presentedFetchErrorMessage = nil
            }
        } message: {
            Text(presentedFetchErrorMessage ?? "")
        }
        .task {
            locationService.start()
            applyPendingStationFocusFromDeepLink()
        }
        .onChange(of: deepLinks.pendingStationFocusID) { _, _ in
            applyPendingStationFocusFromDeepLink()
        }
        .onChange(of: stationStore.stations) { _, _ in
            applyPendingStationFocusFromDeepLink()
        }
        .onChange(of: stationStore.loadState) { _, newState in
            switch newState {
            case let .failed(message):
                presentedFetchErrorMessage = message
            default:
                presentedFetchErrorMessage = nil
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                locationService.refreshAuthorizationStatus()
            }
        }
        .onChange(of: locationService.currentLocation) { _, newValue in
            guard let location = newValue else { return }
            stationStore.handleLocationUpdate(location, radiusKm: AppSettings.SearchRadius.apiMaxKm)
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
                .accessibilityLabel("Tankstellen werden geladen")
                .padding(TRSpacing.s)
                .background(.ultraThinMaterial, in: Capsule())
                .padding(.top, TRSpacing.s)
        default:
            EmptyView()
        }
    }

    /// Zentriert die Karte auf den aktuellen User-Standort.
    ///
    /// TAN-87: Apple-Maps-ähnliches Tracking-Niveau (~1,5 km Radius) statt vorheriger 8 km
    /// Übersicht — beim Tap auf den Locate-Button erwarten Nutzer:innen Straßen-/Block-Klarheit,
    /// nicht nur eine grobe Stadtansicht. Der Initial-Zoom (12 km direkt nach Permission-Grant
    /// in `onChange(of: locationService.currentLocation)`) bleibt absichtlich unberührt — das
    /// ist der „Hier ist deine Region"-Moment, nicht der Tracking-Use-Case.
    ///
    /// Animation respektiert `accessibilityReduceMotion`: ohne Bewegungs-Empfindlichkeit ein
    /// sanfter `.easeInOut`-Übergang, mit Reduce Motion ein sofortiger Snap (kein Zoom-Flow).
    private func centerMapOnUser() {
        guard let location = locationService.currentLocation else { return }
        let region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: 1_500,
            longitudinalMeters: 1_500
        )
        if reduceMotion {
            cameraPosition = .region(region)
        } else {
            withAnimation(.easeInOut(duration: 0.45)) {
                cameraPosition = .region(region)
            }
        }
    }

    private func refreshStations() async {
        guard let location = locationService.currentLocation else { return }
        stationStore.forceRefresh(using: location, radiusKm: AppSettings.SearchRadius.apiMaxKm)
        try? await Task.sleep(for: .milliseconds(400))
    }

    /// Erneuter Abruf nach Netzwerk-/API-Fehler (`StationStore.forceRefresh`).
    private func retryStationFetch() {
        guard let location = locationService.currentLocation else { return }
        stationStore.forceRefresh(using: location, radiusKm: AppSettings.SearchRadius.apiMaxKm)
    }

    /// Kurzbefehle / Custom-URL (`FuelNowDeepLink`): Sheet und Kamera, sobald die Station geladen ist.
    private func applyPendingStationFocusFromDeepLink() {
        guard let id = deepLinks.pendingStationFocusID else { return }
        guard let station = stationStore.stations.first(where: { $0.id == id }) else { return }
        selectedStation = station
        cameraPosition = .region(
            MKCoordinateRegion(
                center: station.coordinate,
                latitudinalMeters: 3_500,
                longitudinalMeters: 3_500
            )
        )
        deepLinks.clearPendingStationFocus()
    }
}

// MARK: - Previews

/// Blauer Punkt wie „Mein Standort“ in Apple Maps (SwiftUI-Annotation, nicht MapKit-`UserAnnotation`).
private struct UserLocationMapMarker: View {
    @ScaledMetric(relativeTo: .body) private var diameter: CGFloat = 18
    @Environment(\.colorScheme) private var colorScheme

    private var haloShadowOpacity: Double {
        colorScheme == .dark ? 0.45 : 0.22
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(Color(uiColor: .systemBlue))
                .frame(width: diameter, height: diameter)
            Circle()
                .strokeBorder(Color.white, lineWidth: 3)
                .frame(width: diameter, height: diameter)
        }
        .shadow(color: .black.opacity(haloShadowOpacity), radius: colorScheme == .dark ? 3 : 2, y: 1)
        .accessibilityLabel("Mein Standort")
        .accessibilityHint("Zeigt deine ungefähre Position auf der Karte.")
    }
}

private struct StationListEnvelope: Decodable {
    let stations: [Station]
}

private struct PreviewThrowingFetcher: StationFetching {
    func fetchStations(latitude: Double, longitude: Double, radiusKm: Double) async throws -> [Station] {
        throw URLError(.notConnectedToInternet)
    }
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

private enum MapScreenPreviewHarness {
    static var deepLinkStore: MapDeepLinkStore {
        MapDeepLinkStore(defaults: UserDefaults(suiteName: "tr.preview.MapScreen.deeplink")!)
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
    .environment(MapScreenPreviewHarness.deepLinkStore)
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        MapScreen()
    }
    .environment(LocationService(streamProvider: PreviewLocationStreamProvider(), authorizationProvider: { .authorizedWhenInUse }))
    .environment(StationStore(fetcher: PreviewStationFetcher(stations: MapScreenPreviewData.stations)))
    .environment(MapScreenPreviewHarness.deepLinkStore)
    .preferredColorScheme(.dark)
}

#Preview("Accessibility 3") {
    NavigationStack {
        MapScreen()
    }
    .environment(LocationService(streamProvider: PreviewLocationStreamProvider(), authorizationProvider: { .authorizedWhenInUse }))
    .environment(StationStore(fetcher: PreviewStationFetcher(stations: MapScreenPreviewData.stations)))
    .environment(MapScreenPreviewHarness.deepLinkStore)
    .environment(\.dynamicTypeSize, .accessibility3)
}

#Preview("Leer — keine Stationen") {
    NavigationStack {
        MapScreen()
    }
    .environment(LocationService(streamProvider: PreviewLocationStreamProvider(), authorizationProvider: { .authorizedWhenInUse }))
    .environment(StationStore(fetcher: PreviewStationFetcher(stations: [])))
    .environment(MapScreenPreviewHarness.deepLinkStore)
    .preferredColorScheme(.light)
}

#Preview("Leer — Dark") {
    NavigationStack {
        MapScreen()
    }
    .environment(LocationService(streamProvider: PreviewLocationStreamProvider(), authorizationProvider: { .authorizedWhenInUse }))
    .environment(StationStore(fetcher: PreviewStationFetcher(stations: [])))
    .environment(MapScreenPreviewHarness.deepLinkStore)
    .preferredColorScheme(.dark)
}

#Preview("Fetch-Fehler") {
    NavigationStack {
        MapScreen()
    }
    .environment(LocationService(streamProvider: PreviewLocationStreamProvider(), authorizationProvider: { .authorizedWhenInUse }))
    .environment(StationStore(fetcher: PreviewThrowingFetcher()))
    .environment(MapScreenPreviewHarness.deepLinkStore)
}
