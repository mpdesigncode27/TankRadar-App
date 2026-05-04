import SwiftUI
import UIKit

/// Vollflächige Erläuterung bei verweigertem oder eingeschränktem Standortzugriff (TAN-21).
struct LocationDeniedCallout: View {
    /// Öffnet das In-App-Einstellungs-Sheet (Spritart, Radius, Datenquelle).
    var openInAppSettings: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var scrimOpacity: Double {
        colorScheme == .dark ? 0.58 : 0.35
    }

    var body: some View {
        ZStack {
            Color.black.opacity(scrimOpacity)
                .ignoresSafeArea()
                .accessibilityHidden(true)

            ContentUnavailableView {
                Label("Standort nicht erlaubt", systemImage: "location.slash.fill")
            } description: {
                Text(
                    "TankRadar braucht deinen Standort, um Tankstellen in der Nähe zu laden. "
                        + "Erlaube unter iOS-Einstellungen → TankRadar → Standort die Option „Beim Verwenden der App“."
                )
                .multilineTextAlignment(.center)
                .accessibilityLabel(
                    "TankRadar braucht deinen Standort, um Tankstellen in der Nähe zu laden. "
                        + "Erlaube unter iOS-Einstellungen, TankRadar, Standort die Option Beim Verwenden der App."
                )
            } actions: {
                Button("iOS-Einstellungen öffnen") {
                    openSystemSettings()
                }
                .buttonStyle(.borderedProminent)

                Button("TankRadar-Einstellungen") {
                    openInAppSettings()
                }
                .buttonStyle(.bordered)
            }
            .padding(TRSpacing.l)
            .background(RoundedRectangle(cornerRadius: TRRadius.lg, style: .continuous).fill(.thinMaterial))
            .padding(TRSpacing.m)
        }
        .accessibilityElement(children: .contain)
    }

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

#Preview("Denied callout") {
    LocationDeniedCallout(openInAppSettings: {})
}
