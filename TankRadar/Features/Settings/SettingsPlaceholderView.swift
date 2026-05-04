import SwiftUI

/// Platzhalter bis **TAN-19** (Spritart, Radius, Attribution).
struct SettingsPlaceholderView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: TRSpacing.m) {
                Text("Spritart, Suchradius und Tankerkönig-Hinweis kommen mit Ticket **TAN-19**.")
                    .font(TRTypography.body())
                    .foregroundStyle(TRColors.labelSecondary)

                Spacer()
            }
            .padding(TRSpacing.m)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(TRColors.background)
            .navigationTitle("Einstellungen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fertig") {
                        dismiss()
                    }
                }
            }
        }
    }
}
