import SwiftUI

/// Platzhalter-Detail bis **TAN-18** (vollständiges Sheet + Apple Maps).
struct StationDetailPlaceholderView: View {
    let station: Station
    let preferredFuel: FuelType

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(station.fullAddress)
                        .font(TRTypography.body())
                        .foregroundStyle(TRColors.labelPrimary)
                } header: {
                    Text("Adresse")
                        .font(TRTypography.caption())
                }

                Section {
                    HStack {
                        Text(preferredFuel.displayName)
                            .font(TRTypography.body())
                        Spacer()
                        if let price = station.price(for: preferredFuel) {
                            Text(price, format: .number.precision(.fractionLength(3)))
                                .font(TRTypography.headline())
                                .foregroundStyle(TRColors.accent)
                            Text("€/l")
                                .font(TRTypography.caption())
                                .foregroundStyle(TRColors.labelSecondary)
                        } else {
                            Text("—")
                                .foregroundStyle(TRColors.labelSecondary)
                        }
                    }
                } header: {
                    Text("Preis")
                        .font(TRTypography.caption())
                }

                Section {
                    Label(station.isOpen ? "Geöffnet" : "Geschlossen", systemImage: station.isOpen ? "door.left.hand.open" : "door.left.hand.closed")
                        .font(TRTypography.callout())
                        .foregroundStyle(TRColors.labelPrimary)
                } header: {
                    Text("Status")
                        .font(TRTypography.caption())
                }
            }
            .navigationTitle(station.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schließen") {
                        dismiss()
                    }
                }
            }
        }
    }
}
