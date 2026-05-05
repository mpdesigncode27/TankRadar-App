import SwiftUI

/// Tankstellen-Pin mit TR-Glas-Pille, Preis für die gewählte Sorte und Öffnungsstatus (grüner bzw. roter Punkt).
struct StationAnnotationView: View {
    let station: Station
    let preferredFuel: FuelType

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @ScaledMetric(relativeTo: .body) private var statusDotDiameter: CGFloat = 12

    private var priceText: String {
        StationAnnotationFormatting.priceString(euros: station.price(for: preferredFuel))
    }

    private var accessibilitySummary: String {
        StationVoiceOverCopy.mapPinSummary(
            stationName: station.name,
            isOpen: station.isOpen,
            priceDisplay: priceText,
            fuelDisplayName: preferredFuel.displayName
        )
    }

    /// Ab `.accessibility3` zweite Zeile erlauben, damit die Pille nicht beschnitten wird (TAN-20).
    private var priceLineLimit: Int {
        dynamicTypeSize >= .accessibility3 ? 2 : 1
    }

    var body: some View {
        HStack(alignment: .center, spacing: TRSpacing.xs) {
            statusBadge
            Text(priceText)
                .font(TRTypography.bodyBold())
                .foregroundStyle(TRColors.labelPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(priceLineLimit)
                .minimumScaleFactor(dynamicTypeSize >= .accessibility3 ? 0.6 : 0.72)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, TRSpacing.s)
        .padding(.vertical, TRSpacing.xxs)
        .frame(minHeight: 44)
        .trGlassPill(interactive: true)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
        .accessibilityHint("Tippen für Details.")
    }

    /// Status-Punkt: Farbe **only** auf bewusste Designentscheidung (TAN-80 Folge).
    /// Die Farbe ist hochkontrastreich (`success` / `danger` jeweils ≥ 4:1 vs. weißes Glas
    /// der Pille); SC 1.4.1 für sehende Nutzer mit Rot-Grün-Schwäche wird in Kauf genommen,
    /// VoiceOver-Label am `accessibilitySummary` bleibt als zweite Info erhalten.
    private var statusBadge: some View {
        Circle()
            .fill(station.isOpen ? TRColors.success : TRColors.danger)
            .frame(width: statusDotDiameter, height: statusDotDiameter)
            .overlay {
                Circle()
                    .strokeBorder(TRColors.background.opacity(0.55), lineWidth: 1)
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
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }()

    static func priceString(euros: Double?) -> String {
        guard let euros else {
            return "—"
        }
        return eurosFormatter.string(from: NSNumber(value: euros)) ?? String(format: "%.2f €", euros)
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
