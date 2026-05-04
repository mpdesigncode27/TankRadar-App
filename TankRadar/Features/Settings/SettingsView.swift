import SwiftUI

/// Einstellungen: Spritart, Suchradius (`@AppStorage`) und Pflichtattribution Tankerkönig (CC BY).
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage(AppSettings.UserDefaultsKey.preferredFuelType) private var preferredFuelRaw = FuelType.e10.rawValue
    @AppStorage(AppSettings.UserDefaultsKey.searchRadiusKm) private var searchRadiusKm = AppSettings.SearchRadius.defaultKm

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("", selection: $preferredFuelRaw) {
                        ForEach(FuelType.allCases) { fuel in
                            Text(fuel.displayName).tag(fuel.rawValue)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .accessibilityLabel("Spritart")
                    .accessibilityHint("Bestimmt, welche Sorte auf der Karte für Preise verwendet wird.")
                } header: {
                    Text("Spritart")
                } footer: {
                    Text("Auf der Karte wird der Preis für die gewählte Sorte angezeigt.")
                }

                Section {
                    VStack(alignment: .leading, spacing: TRSpacing.s) {
                        HStack {
                            Text("Suchradius")
                                .font(TRTypography.body())
                            Spacer()
                            Text("\(searchRadiusKm) km")
                                .font(TRTypography.callout())
                                .foregroundStyle(TRColors.labelSecondary)
                                .accessibilityHidden(true)
                        }
                        Slider(
                            value: Binding(
                                get: { Double(searchRadiusKm) },
                                set: { searchRadiusKm = AppSettings.SearchRadius.clampedKm(sliderValue: $0) }
                            ),
                            in: Double(AppSettings.SearchRadius.minKm)...Double(AppSettings.SearchRadius.maxKm),
                            step: 1
                        )
                        .tint(TRColors.accent)
                        .accessibilityLabel("Suchradius")
                        .accessibilityValue("\(searchRadiusKm) Kilometer")
                    }
                } footer: {
                    Text("Tankstellen werden bis zu diesem Radius geladen (max. 25 km, entsprechend Tankerkönig).")
                }

                Section {
                    Link(destination: AppSettings.TankerkoenigAttribution.infoURL) {
                        Label("Tankerkönig / MTS-K (CC BY 4.0)", systemImage: "link")
                    }
                    .accessibilityLabel("Tankerkönig und MTS-K, Lizenz CC BY 4.0")
                    .accessibilityHint("Öffnet die Tankerkönig-Website mit Lizenzinformationen.")
                } footer: {
                    Text("Datenquelle und Pflichtattribution für die Nutzung der Tankerkönig-API.")
                }
            }
            .navigationTitle("Einstellungen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(TRColors.labelSecondary, TRColors.labelTertiary.opacity(0.35))
                    }
                    .accessibilityLabel("Schließen")
                    .accessibilityHint("Schließt die Einstellungen.")
                }
            }
        }
    }
}

#Preview("Light") {
    SettingsView()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    SettingsView()
        .preferredColorScheme(.dark)
}

#Preview("Accessibility 3") {
    SettingsView()
        .environment(\.dynamicTypeSize, .accessibility3)
}
