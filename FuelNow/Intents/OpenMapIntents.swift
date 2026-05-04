import AppIntents
import Foundation

/// Öffnet die App zur Karte (Deep-Link-Flow ohne zusätzliche Parameter).
struct OpenFuelNowIntent: AppIntent {
    static var title: LocalizedStringResource {
        LocalizedStringResource("intent.openFuelNow.title")
    }

    static var description: IntentDescription {
        IntentDescription(
            LocalizedStringResource("intent.openFuelNow.description")
        )
    }

    static var openAppWhenRun: Bool { true }

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            MapDeepLinkStore.shared.clearPendingStationFocus()
        }
        return .result()
    }
}

/// Öffnet die App und fokussiert die gewählte Tankstelle auf der Karte.
struct OpenStationIntent: AppIntent {
    static var title: LocalizedStringResource {
        LocalizedStringResource("intent.openStation.title")
    }

    static var description: IntentDescription {
        IntentDescription(
            LocalizedStringResource("intent.openStation.description")
        )
    }

    static var openAppWhenRun: Bool { true }

    @Parameter(title: LocalizedStringResource("intent.openStation.parameter.station"))
    var station: StationEntity

    init() {}

    init(station: StationEntity) {
        self.station = station
    }

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            MapDeepLinkStore.shared.enqueueStationFocus(id: station.id)
        }
        return .result()
    }
}
