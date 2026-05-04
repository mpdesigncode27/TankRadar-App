import SwiftUI

/// Tankstellen-Pin mit TR-Glas-Pille, Preis für die gewählte Sorte und Öffnungsstatus (Farbe + Symbol).
struct StationAnnotationView: View {
    let station: Station
    let preferredFuel: FuelType

    @ScaledMetric(relativeTo: .body) private var statusDotDiameter: CGFloat = 10
    @ScaledMetric(relativeTo: .body) private var statusSymbolPointSize: CGFloat = 9

    private var priceText: String {
        StationAnnotationFormatting.priceString(euros: station.price(for: preferredFuel))
    }

    private var accessibilityStatusPhrase: String {
        station.isOpen ? "Geöffnet" : "Geschlossen"
    }

    private var accessibilitySummary: String {
        "\(station.name). \(accessibilityStatusPhrase). \(priceText) für \(preferredFuel.displayName)."
    }

    var body: some View {
        HStack(spacing: TRSpacing.xs) {
            statusBadge
            Text(priceText)
                .font(TRTypography.bodyBold())
                .foregroundStyle(TRColors.labelPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .padding(.horizontal, TRSpacing.s)
        .padding(.vertical, TRSpacing.xxs)
        .trGlassPill(interactive: true)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Details zur Tankstelle anzeigen.")
    }

    private var statusBadge: some View {
        ZStack {
            Circle()
                .fill(station.isOpen ? TRColors.success : TRColors.danger)
                .frame(width: statusDotDiameter, height: statusDotDiameter)
                .overlay {
                    Circle()
                        .strokeBorder(TRColors.background.opacity(0.55), lineWidth: 1)
                }
            Image(systemName: station.isOpen ? "fuelpump.fill" : "moon.zzz.fill")
                .font(.system(size: statusSymbolPointSize, weight: .bold))
                .foregroundStyle(.white.opacity(0.95))
                .accessibilityHidden(true)
        }
        .accessibilityHidden(true)
    }
}

private enum StationAnnotationFormatting {
    private static let eurosFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        formatter.locale = Locale(identifier: "de_DE")
        formatter.maximumFractionDigits = 3
        formatter.minimumFractionDigits = 2
        return formatter
    }()

    static func priceString(euros: Double?) -> String {
        guard let euros else {
            return "—"
        }
        return eurosFormatter.string(from: NSNumber(value: euros)) ?? String(format: "%.3f €", euros)
    }
}

// MARK: - Previews

private struct StationPreviewEnvelope: Decodable {
    let stations: [Station]
}

#Preview("Station pin · Standard Dynamic Type") {
    previewStationRow(dynamicType: .medium)
}

#Preview("Station pin · Accessibility 3") {
    previewStationRow(dynamicType: .accessibility3)
}

private func previewStationRow(dynamicType: DynamicTypeSize) -> some View {
    let json = Data(
        """
        {"stations":[
          {"id":"474e5046-deaf-4f9b-9a32-9797b778f047","name":"TOTAL BERLIN","brand":"TOTAL","street":"X","place":"BERLIN","lat":52.53,"lng":13.44,"dist":1.1,"diesel":1.109,"e5":1.339,"e10":1.319,"isOpen":true,"houseNumber":"2","postCode":10407},
          {"id":"474e5046-deaf-4f9b-9a32-9797b778f048","name":"CLOSED SAMPLE","brand":"SHELL","street":"Y","place":"BERLIN","lat":52.54,"lng":13.45,"dist":2,"diesel":null,"e5":1.499,"e10":null,"isOpen":false,"houseNumber":"1","postCode":10115}
        ]}
        """.utf8
    )
    let stations = (try? JSONDecoder().decode(StationPreviewEnvelope.self, from: json).stations) ?? []

    return VStack(spacing: TRSpacing.l) {
        ForEach(stations) { station in
            StationAnnotationView(station: station, preferredFuel: .e10)
        }
    }
    .padding(TRSpacing.l)
    .background(TRColors.background)
    .environment(\.dynamicTypeSize, dynamicType)
}
