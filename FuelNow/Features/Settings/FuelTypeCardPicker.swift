import SwiftUI

/// Karten-Auswahl für die bevorzugte Kraftstoffsorte (TAN-78).
///
/// Ersetzt den kompakten `Picker(.menu)` durch drei großflächige Karten (Glyph + Titel + Untertitel)
/// mit Liquid-Glass-Akzent-Tint auf der aktiven Karte. Mehrere Karten teilen sich einen
/// `GlassEffectContainer`, damit nichts „Glas-auf-Glas“ stapelt (HIG iOS 26).
struct FuelTypeCardPicker: View {
    @Binding var selection: FuelType

    var body: some View {
        GlassEffectContainer(spacing: TRSpacing.s) {
            VStack(spacing: TRSpacing.s) {
                ForEach(FuelType.allCases) { fuel in
                    FuelTypeCard(
                        fuel: fuel,
                        isSelected: fuel == selection,
                        action: { selection = fuel }
                    )
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("settings.fuel.row.title"))
        .accessibilityValue(Text(selection.displayName))
    }
}

private struct FuelTypeCard: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let fuel: FuelType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            cardContent
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(fuel.displayName))
        .accessibilityValue(Text(fuel.settingsCardSubtitleKey))
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityHint(Text("settings.fuel.card.a11yHint"))
        .animation(reduceMotion ? nil : .easeOut(duration: 0.18), value: isSelected)
    }

    private var cardContent: some View {
        HStack(alignment: .center, spacing: TRSpacing.m) {
            Image(systemName: fuel.settingsCardSymbolName)
                .font(.title2)
                .foregroundStyle(isSelected ? TRColors.accent : TRColors.labelSecondary)
                .frame(width: 36, height: 36, alignment: .center)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: TRSpacing.xxs) {
                Text(fuel.displayName)
                    .font(TRTypography.bodyBold())
                    .foregroundStyle(TRColors.labelPrimary)
                Text(fuel.settingsCardSubtitleKey)
                    .font(TRTypography.callout())
                    .foregroundStyle(TRColors.labelSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(TRColors.accent)
                    .accessibilityHidden(true)
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .padding(.horizontal, TRSpacing.m)
        .padding(.vertical, TRSpacing.s)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(FuelTypeCardSurface(isSelected: isSelected))
        .contentShape(RoundedRectangle(cornerRadius: TRRadius.lg, style: .continuous))
    }
}

/// Liquid-Glass-Fläche der Karte: aktiver Zustand mit Akzent-Tint, inaktiv `regularMaterial`.
/// Bei „Transparenz reduzieren“ entfällt das Glas; aktive Karte erhält sichtbare Akzent-Outline.
private struct FuelTypeCardSurface: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    let isSelected: Bool

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: TRRadius.lg, style: .continuous)

        if reduceTransparency {
            content
                .background(.regularMaterial, in: shape)
                .overlay {
                    if isSelected {
                        shape.strokeBorder(TRColors.accent, lineWidth: 1.5)
                    } else {
                        shape.strokeBorder(TRColors.separator.opacity(0.6), lineWidth: 1)
                    }
                }
        } else if isSelected {
            content.glassEffect(
                Glass.regular.tint(TRColors.accent.opacity(0.30)).interactive(),
                in: .rect(cornerRadius: TRRadius.lg)
            )
        } else {
            content
                .background(.regularMaterial, in: shape)
                .overlay(shape.strokeBorder(TRColors.separator.opacity(0.4), lineWidth: 1))
        }
    }
}

#Preview("Light") {
    StatefulPreviewWrapper(FuelType.e10) { binding in
        FuelTypeCardPicker(selection: binding)
            .padding()
            .background(TRColors.background)
    }
}

#Preview("Dark") {
    StatefulPreviewWrapper(FuelType.diesel) { binding in
        FuelTypeCardPicker(selection: binding)
            .padding()
            .background(TRColors.background)
            .preferredColorScheme(.dark)
    }
}

#Preview("Accessibility 3") {
    StatefulPreviewWrapper(FuelType.e10) { binding in
        FuelTypeCardPicker(selection: binding)
            .padding()
            .background(TRColors.background)
            .environment(\.dynamicTypeSize, .accessibility3)
    }
}

private struct StatefulPreviewWrapper<Value, Content: View>: View {
    @State private var value: Value
    let content: (Binding<Value>) -> Content

    init(_ initialValue: Value, @ViewBuilder content: @escaping (Binding<Value>) -> Content) {
        _value = State(initialValue: initialValue)
        self.content = content
    }

    var body: some View {
        content($value)
    }
}
