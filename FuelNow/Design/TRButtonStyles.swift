import SwiftUI

// MARK: - Primary (accent-tinted glass)

/// Hauptaktion: Liquid Glass mit Akzent-Tint (iOS 26); Material bei „Transparenz reduzieren“.
struct TRPrimaryGlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        TRPrimaryGlassButtonBody(configuration: configuration)
    }
}

private struct TRPrimaryGlassButtonBody: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let configuration: ButtonStyle.Configuration

    var body: some View {
        configuration.label
            .font(TRTypography.bodyBold())
            .foregroundStyle(TRColors.labelPrimary)
            .padding(.horizontal, TRSpacing.l)
            .padding(.vertical, TRSpacing.xs)
            .opacity(configuration.isPressed ? 0.88 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
            .modifier(TRAdaptiveGlassSurfaceModifier(surface: .primaryTintCapsule))
    }
}

// MARK: - Soft (neutral glass)

/// Sekundäre Aktion: dezentes Glas / Material.
struct TRSoftButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        TRSoftGlassButtonBody(configuration: configuration)
    }
}

private struct TRSoftGlassButtonBody: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let configuration: ButtonStyle.Configuration

    var body: some View {
        configuration.label
            .font(TRTypography.bodyBold())
            .foregroundStyle(TRColors.labelPrimary)
            .padding(.horizontal, TRSpacing.l)
            .padding(.vertical, TRSpacing.xs)
            .opacity(configuration.isPressed ? 0.88 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
            .modifier(TRAdaptiveGlassSurfaceModifier(surface: .softCapsule))
    }
}

// MARK: - Outline

/// Ghost / Tertiär: nur Kontur, kein Glas.
struct TROutlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        TROutlineButtonBody(configuration: configuration)
    }
}

private struct TROutlineButtonBody: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let configuration: ButtonStyle.Configuration

    var body: some View {
        configuration.label
            .font(TRTypography.bodyBold())
            .foregroundStyle(TRColors.accentText)
            .padding(.horizontal, TRSpacing.l)
            .padding(.vertical, TRSpacing.xs)
            .background(Capsule().fill(TRColors.backgroundSecondary.opacity(0.001)))
            .overlay {
                Capsule()
                    .strokeBorder(TRColors.accentText, lineWidth: 1.5)
            }
            .opacity(configuration.isPressed ? 0.75 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == TRPrimaryGlassButtonStyle {
    static var trPrimaryGlass: TRPrimaryGlassButtonStyle { TRPrimaryGlassButtonStyle() }
}

extension ButtonStyle where Self == TRSoftButtonStyle {
    static var trSoft: TRSoftButtonStyle { TRSoftButtonStyle() }
}

extension ButtonStyle where Self == TROutlineButtonStyle {
    static var trOutline: TROutlineButtonStyle { TROutlineButtonStyle() }
}
