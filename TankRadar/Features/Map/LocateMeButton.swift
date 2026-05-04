import SwiftUI

/// „Standort zentrieren“ mit Liquid Glass, Mindest-Tap-Target 44×44 und haptischem Feedback nur beim Tap (Trigger-Zähler, nicht von Daten-IDs abhängig).
struct LocateMeButton: View {
    let action: () -> Void

    @ScaledMetric(relativeTo: .body) private var iconSize: CGFloat = 22
    @State private var sensoryTapTrigger: UInt = 0

    var body: some View {
        Button {
            sensoryTapTrigger += 1
            action()
        } label: {
            Image(systemName: "location.fill")
                .font(.system(size: iconSize, weight: .semibold))
                .foregroundStyle(TRColors.labelPrimary)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Circle())
                .glassEffect(Glass.regular.interactive(), in: Circle())
                .shadow(color: .black.opacity(0.12), radius: TRSpacing.xxs, y: 2)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(weight: .medium), trigger: sensoryTapTrigger)
        .accessibilityLabel("Karte auf Standort zentrieren")
        .accessibilityHint("Zentriert die Karte auf deinen aktuellen Standort.")
    }
}

#Preview("Locate · Light") {
    LocateMeButton {}
        .padding(TRSpacing.xl)
        .background(TRColors.background)
        .preferredColorScheme(.light)
}

#Preview("Locate · Dark · XL Type") {
    LocateMeButton {}
        .padding(TRSpacing.xl)
        .background(TRColors.background)
        .preferredColorScheme(.dark)
        .environment(\.dynamicTypeSize, .accessibility1)
}
