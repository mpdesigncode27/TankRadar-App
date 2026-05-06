import CoreLocation
import MapKit
import SwiftUI

/// Detail-Sheet für eine Tankstelle: Marke in der Navigationsleiste, Status/Entfernung, Spritpreise und Apple-Maps-Navigation (Autoroute).
struct StationDetailView: View {
    let station: Station
    let preferredFuel: FuelType

    @Environment(\.dismiss) private var dismiss

    /// Marke in der Toolbar; wenn leer, voller Stationsname.
    private var navigationBarBrandTitle: String {
        let trimmed = station.brand.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? station.name : trimmed
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                statusAndDistanceRow
                    .padding(.horizontal, TRSpacing.m)
                    .padding(.top, TRSpacing.s)
                    .padding(.bottom, TRSpacing.m)

                ScrollView {
                    VStack(alignment: .leading, spacing: TRSpacing.m) {
                        TRSectionCard(title: "Preise") {
                            VStack(alignment: .leading, spacing: TRSpacing.s) {
                                ForEach(FuelType.allCases) { fuel in
                                    priceRow(fuel: fuel, isPreferred: fuel == preferredFuel)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, TRSpacing.m)
                    .padding(.bottom, TRSpacing.m)
                }

                appleMapsNavigationButton
                    .padding(.horizontal, TRSpacing.m)
                    .padding(.top, TRSpacing.s)
                    .padding(.bottom, TRSpacing.m)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(navigationBarBrandTitle)
                        .font(.headline)
                        .foregroundStyle(TRColors.labelPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .accessibilityLabel(station.name)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title3.weight(.medium))
                            .foregroundStyle(TRColors.labelSecondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Schließen")
                    .accessibilityHint("Schließt die Tankstellendetails.")
                }
            }
        }
    }

    /// Status und Entfernung unter der Toolbar (fix, ohne Scrollen).
    @ViewBuilder
    private var statusAndDistanceRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: TRSpacing.m) {
            HStack(spacing: TRSpacing.s) {
                Circle()
                    .fill(station.isOpen ? TRColors.success : TRColors.danger)
                    .frame(width: 12, height: 12)
                    .overlay {
                        Circle()
                            .strokeBorder(TRColors.labelPrimary.opacity(0.12), lineWidth: 1)
                    }
                    .accessibilityHidden(true)
                Text(station.isOpen ? "Geöffnet" : "Geschlossen")
                    .font(TRTypography.callout())
                    .fontWeight(.semibold)
                    .foregroundStyle(station.isOpen ? TRColors.success : TRColors.danger)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(station.isOpen ? "Geöffnet" : "Geschlossen")

            Spacer(minLength: TRSpacing.s)

            Text(distanceLabel)
                .font(TRTypography.callout())
                .foregroundStyle(TRColors.labelSecondary)
                .multilineTextAlignment(.trailing)
                .accessibilityLabel("Entfernung, \(distanceLabel)")
        }
    }

    private var appleMapsNavigationButton: some View {
        Button(action: startAppleMapsDrivingNavigation) {
            Label("Navigation in Apple Maps", systemImage: "location.north.line.fill")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.trPrimaryGlass)
        .accessibilityLabel("Navigation in Apple Maps")
        .accessibilityHint("Startet die Autoroute von deinem Standort zur Tankstelle in Apple Maps.")
    }

    private var distanceLabel: String {
        StationDetailFormatting.distanceString(kilometers: station.distanceKilometers)
    }

    private func priceRow(fuel: FuelType, isPreferred: Bool) -> some View {
        HStack(alignment: .firstTextBaseline) {
            HStack(spacing: TRSpacing.xxs) {
                Text(fuel.displayName)
                    .font(TRTypography.body())
                    .foregroundStyle(TRColors.labelPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                if isPreferred {
                    Image(systemName: "checkmark.circle.fill")
                        .font(TRTypography.caption())
                        .foregroundStyle(TRColors.accentText)
                        .accessibilityHidden(true)
                }
            }
            Spacer(minLength: TRSpacing.s)
            Group {
                if let euros = station.price(for: fuel) {
                    Text(StationDetailFormatting.priceString(euros: euros))
                        .font(TRTypography.bodyBold())
                        .foregroundStyle(TRColors.accentText)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                } else {
                    Text("—")
                        .font(TRTypography.bodyBold())
                        .foregroundStyle(TRColors.labelSecondary)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(priceRowAccessibilityLabel(fuel: fuel, isPreferred: isPreferred))
    }

    private func priceRowAccessibilityLabel(fuel: FuelType, isPreferred: Bool) -> String {
        let pricePart: String
        if let euros = station.price(for: fuel) {
            pricePart = StationDetailFormatting.priceString(euros: euros)
        } else {
            pricePart = "Kein Preis verfügbar"
        }
        return StationVoiceOverCopy.detailPriceRow(
            fuelDisplayName: fuel.displayName,
            formattedPriceOrUnavailable: pricePart,
            isPreferred: isPreferred
        )
    }

    private func startAppleMapsDrivingNavigation() {
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

private enum StationDetailFormatting {
    private static let eurosFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        formatter.locale = Locale(identifier: "de_DE")
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }()

    private static let distanceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        formatter.numberStyle = .decimal
        return formatter
    }()

    static func priceString(euros: Double) -> String {
        eurosFormatter.string(from: NSNumber(value: euros)) ?? String(format: "%.2f €", euros)
    }

    static func distanceString(kilometers: Double?) -> String {
        guard let kilometers else {
            return "—"
        }
        let formatted = distanceFormatter.string(from: NSNumber(value: kilometers)) ?? String(format: "%.1f", kilometers)
        return "ca. \(formatted) km"
    }
}

// MARK: - Previews

private struct StationDetailPreviewEnvelope: Decodable {
    let stations: [Station]
}

#Preview("Station detail · Standard") {
    previewStationDetail(dynamicType: .medium)
}

#Preview("Station detail · Accessibility 3") {
    previewStationDetail(dynamicType: .accessibility3)
}

#Preview("Station detail · Accessibility XXL") {
    previewStationDetail(dynamicType: .accessibility5)
}

private func previewStationDetail(dynamicType: DynamicTypeSize) -> some View {
    let json = Data(
        """
        {"stations":[{"id":"474e5046-deaf-4f9b-9a32-9797b778f047","name":"TOTAL BERLIN","brand":"TOTAL","street":"MARGARETE-SOMMER-STR.","place":"BERLIN","lat":52.53083,"lng":13.440946,"dist":1.12,"diesel":1.109,"e5":1.339,"e10":1.319,"isOpen":true,"houseNumber":"2","postCode":10407}]}
        """.utf8
    )
    let station = (try? JSONDecoder().decode(StationDetailPreviewEnvelope.self, from: json).stations.first)!
    return NavigationStack {
        StationDetailView(station: station, preferredFuel: .e10)
    }
    .environment(\.dynamicTypeSize, dynamicType)
}
